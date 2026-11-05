import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    videoIds: Array,
    defaultFocusMode: Boolean,
    startStopTimes: Object // { videoId: { start: seconds, end: seconds } }
  }

  static targets = [
    "playerContainer", "focusControls", "focusToggle", "mobileWarning", "videoTitleBox", "videoTitle",
    "settingsButton", "settingsCard", "startSlider", "endSlider", "rangeFill",
    "scaleMin", "scaleMax", "startOutput", "endOutput", "saveButton", "settingsStatus"
  ]

  connect() {
    window.playerController = this;

    // Detect mobile browsers (simple heuristic: screen width + user agent)
    const isMobile = /Mobi|Android/i.test(navigator.userAgent);

    if (isMobile) {
      ahoy.track("mobile_warning_displayed", { user_agent: navigator.userAgent});
      // Show warning, hide player and its controls
      this.mobileWarningTarget.classList.remove("hidden");
      this.playerContainerTarget.classList.add("hidden");
      this.focusControlsTarget.classList.add("hidden");
      return; // Don’t initialize the player
    }

    this.focusMode = window.innerWidth <= 768 ? true : this.defaultFocusModeValue;
    this.applyFocusMode();

    this.boundHandleKeydown = this.handleKeydown.bind(this);
    document.addEventListener("keydown", this.boundHandleKeydown);

    this.boundFitTitle = this.fitTitle.bind(this);
    window.addEventListener("resize", this.boundFitTitle);

    this.loadYouTubeAPI().then(() => this.initPlayer());
  }

  disconnect() {
    this.trackSessionEnded();
    this.stopWatchdog();
    this.stopEndTimeCheck();
    if (this.boundHandleKeydown) {
      document.removeEventListener("keydown", this.boundHandleKeydown);
    }
    if (this.boundFitTitle) {
      window.removeEventListener("resize", this.boundFitTitle);
    }
  }

  initPlayer() {
    this.currentIndex = 0;

    this.player = new YT.Player("player-container", {
      height: "390",
      width: "640",
      videoId: this.videoIdsValue[this.currentIndex],
      host: "https://www.youtube-nocookie.com",
      playerVars: {
        autoplay:       1,
        controls:       1,
        mute:           0,
        rel:            0,
        playlist:       this.videoIdsValue.join(","),
        enablejsapi:    1,
        iv_load_policy: 3,
      },
      events: {
        onReady: this.onReady.bind(this),
        onStateChange: this.onStateChange.bind(this),
        onError: this.onError.bind(this)
      },
    })
    const player_version = document.getElementById('www-widgetapi-script')?.src?.match(/\/player\/([a-f0-9]+)\//)?.[1];
    ahoy.track("player_initialized", {video_ids: this.videoIdsValue, player_version: player_version});
  }

  toggleFocus() {
    ahoy.track("toggle_focus", {current_mode_before_toggle: this.focusMode});
    this.focusMode = !this.focusMode;
    this.applyFocusMode();
  }

  applyFocusMode() {
    if (this.focusMode) {
      this.element.classList.add("focus-mode");

      if (this.hasFocusToggleTarget) { this.focusToggleTarget.checked = true }
    } else {
      this.element.classList.remove("focus-mode");

      if (this.hasFocusToggleTarget) { this.focusToggleTarget.checked = false }
    }
  }

  playPause() {
    if (!this.player || typeof this.player.getPlayerState !== "function") return;
    const state = this.player.getPlayerState();
    if (state === YT.PlayerState.PLAYING) {
      ahoy.track("pause_button_pushed", this.getCurrentVideoInfo());
      this.player.pauseVideo();
    } else {
      ahoy.track("play_button_pushed", this.getCurrentVideoInfo());
      this.player.playVideo();
    }
  }

  nextVideo() {
    if (!this.player || typeof this.player.nextVideo !== "function") return;
    ahoy.track("next_button_pushed", this.getCurrentVideoInfo());
    this.lastKnownTime = null; // Reset lastKnownTime each time a new song is played so that checkPlayerHealth doesn't incorrectly think the player is frozen
    this.player.nextVideo();
  }

  prevVideo() {
    if (!this.player || typeof this.player.previousVideo !== "function") return;
    ahoy.track("previous_button_pushed", this.getCurrentVideoInfo());
    this.player.previousVideo();
  }

  repeatVideo() {
    // TODO: Implement this as an actual feature if it becomes requested
    //       - player.setLoopVideo(true) doesn't seem to be working as I expect, need to research
  }

  updateTitle() {
    const videoData = this.player.getVideoData && this.player.getVideoData();
    if (videoData && videoData.title) {
      document.title = videoData.title;
      this.videoTitleTarget.innerText = videoData.title;
      this.videoTitleBoxTarget.title = videoData.title; // Full title on hover if it still gets cut off
      this.fitTitle();
    } else {
      document.title = "YouTube Player";
    }
  }

  // The title box has a fixed height. Start at the largest font size and shrink until the title fits.
  // Titles that are still too long at the smallest size get cut off with an ellipsis (see .clamped).
  fitTitle() {
    if (!this.hasVideoTitleTarget) return;
    const box   = this.videoTitleBoxTarget;
    const title = this.videoTitleTarget;
    const maxRem = 1.6, minRem = 1, stepRem = 0.05;

    box.classList.remove("clamped");
    let size = maxRem;
    title.style.fontSize = `${size}rem`;
    while (size > minRem && title.offsetHeight > box.clientHeight) {
      size = Math.max(minRem, size - stepRem);
      title.style.fontSize = `${size}rem`;
    }
    box.classList.toggle("clamped", title.offsetHeight > box.clientHeight);
  }

  onStart() {
    console.log("OnStart triggered!")
  }

  onError(event) {
    ahoy.track("on_error_triggered", { ...this.getCurrentVideoInfo(), error_code: event.data });
    console.log("OnError triggered, code:", event.data, this.player.getVideoData());
    this.player.nextVideo();
  }

  onEnded() {
    ahoy.track("playlist_ended", this.getCurrentVideoInfo());
    this.lastKnownTime = null; // Reset lastKnownTime each time a new song is played so that checkPlayerHealth doesn't incorrectly think the player is frozen
    // Need to load the next set of shuffled videos from the playlist(s) here
    // TODO: Looks like onEnded() gets called when users manually select another video in the playlist, so we need to handle that case too
    console.log("Playlist ended, refresh the page. We haven't implemented an auto fetch yet.")
    location.reload();
  }

  onReady() {
    window.player = this.player;
    this.updateTitle(); // Set title when ready
    this.startWatchdog();
    this.startEndTimeCheck();
    console.log("Player is ready!");
  }

  startWatchdog() {
    this.lastKnownTime = null;
    this.bufferingStartedAt = null;
    this.playerStartedAt = Date.now();
    this.videosPlayedCount = 0;
    this.lastPlayingVideoId = null;
    this.sessionEndedTracked = false;
    this.watchdogInterval = setInterval(() => this.checkPlayerHealth(), 15000);

    // pagehide catches full unloads/reloads (e.g. onEnded reload); disconnect catches Turbo navigations
    this.boundTrackSessionEnded = this.trackSessionEnded.bind(this);
    window.addEventListener("pagehide", this.boundTrackSessionEnded);
  }

  stopWatchdog() {
    if (this.watchdogInterval) {
      clearInterval(this.watchdogInterval);
      this.watchdogInterval = null;
    }
    if (this.boundTrackSessionEnded) {
      window.removeEventListener("pagehide", this.boundTrackSessionEnded);
      this.boundTrackSessionEnded = null;
    }
  }

  trackSessionEnded() {
    if (this.sessionEndedTracked || !this.playerStartedAt) return;
    this.sessionEndedTracked = true;

    ahoy.track("player_session_ended", {
      session_seconds: (Date.now() - this.playerStartedAt) / 1000,
      videos_played_count: this.videosPlayedCount,
      last_video_id: this.lastPlayingVideoId,
    });
  }

  memorySnapshot() {
    if (!performance.memory) return {};
    return {
      js_heap_used_mb:  Math.round(performance.memory.usedJSHeapSize  / 1048576),
      js_heap_total_mb: Math.round(performance.memory.totalJSHeapSize / 1048576),
      js_heap_limit_mb: Math.round(performance.memory.jsHeapSizeLimit / 1048576),
    };
  }

  checkPlayerHealth() {
    if (!this.player || typeof this.player.getPlayerState !== "function") return;

    const state       = this.player.getPlayerState();
    const currentTime = this.player.getCurrentTime();
    const videoData   = this.player.getVideoData() || {};

    const base = { player_state: state, current_time: currentTime, ...videoData, ...this.memorySnapshot() };

    if (state === YT.PlayerState.PLAYING) {
      if (this.lastKnownTime !== null && currentTime <= this.lastKnownTime) {
        const sessionSeconds = (Date.now() - this.playerStartedAt) / 1000;
        ahoy.track("player_watchdog_frozen", {
          ...base,
          last_known_time: this.lastKnownTime,
          videos_played_count: this.videosPlayedCount,
          session_seconds: sessionSeconds,
        });
        console.warn("Watchdog: player appears frozen at", currentTime, `(${this.videosPlayedCount} videos played, session ${Math.round(sessionSeconds)}s)`);
      }
      this.bufferingStartedAt = null;
    }

    if (state === YT.PlayerState.BUFFERING && this.bufferingStartedAt !== null) {
      const bufferingSeconds = (Date.now() - this.bufferingStartedAt) / 1000;
      if (bufferingSeconds > 30) {
        ahoy.track("player_watchdog_buffering_timeout", {
          ...base,
          buffering_seconds: bufferingSeconds,
        });
        console.warn("Watchdog: buffering for", bufferingSeconds, "seconds");
      }
    }

    // An UNSTARTED state mid-session (not at t=0) is a signal the player reset unexpectedly
    if (state === YT.PlayerState.UNSTARTED && this.lastKnownTime !== null && this.lastKnownTime > 0) {
      ahoy.track("player_watchdog_unexpected_unstarted", {
        ...base,
        last_known_time: this.lastKnownTime,
      });
      console.warn("Watchdog: unexpected UNSTARTED state after", this.lastKnownTime, "seconds");
    }

    this.lastKnownTime = currentTime;
  }

  onStateChange(event) {
    // https://web.archive.org/web/20250727111728/https://developers.google.com/youtube/iframe_api_reference#Playback_status
    //
    // Possible states:
    // YT.PlayerState.PAUSED
    // YT.PlayerState.BUFFERING
    // YT.PlayerState.CUED

    let state;
    switch(event.data) {
      case YT.PlayerState.PAUSED:
        state = "PLAYER_STATE_CHANGE_TO_PAUSED";
        break;
      case YT.PlayerState.BUFFERING:
        state = "PLAYER_STATE_CHANGE_TO_BUFFERING";
        this.bufferingStartedAt = Date.now();
        break;
      case YT.PlayerState.CUED:
        state = "PLAYER_STATE_CHANGE_TO_CUED";
        break;
      case YT.PlayerState.UNSTARTED:
        state = "PLAYER_STATE_CHANGE_TO_UNSTARTED";
        break;
      case YT.PlayerState.ENDED:
        state = "PLAYER_STATE_CHANGE_TO_ENDED";
        break;
      case YT.PlayerState.PLAYING:
        state = "PLAYER_STATE_CHANGE_TO_PLAYING";
        break;
    }
    ahoy.track(state, this.player.getVideoData());

    switch(event.data) {
      case YT.PlayerState.UNSTARTED:
        if (this.player.getVideoData().errorCode) {
          // NOTE: This gets called AFTER the onError() triggers
          console.log("Video is unstarted with error:", this.player.getVideoData());
        }
        break;
      case YT.PlayerState.ENDED:
        this.onEnded();
        break;
      case YT.PlayerState.PLAYING: {
        this.updateTitle(); // Update title on play
        const currentVideoId = this.player.getVideoData().video_id;
        if (currentVideoId && currentVideoId !== this.lastPlayingVideoId) {
          this.videosPlayedCount++;
          this.lastPlayingVideoId = currentVideoId;
          this.skippedAtEndTime = false;
          this.applyStartTime(currentVideoId);
          if (this.settingsOpen()) { this.populateSettingsCard() } // Card follows the video that's playing
        }
        break;
      }
    }
  }

  // ---- Start/end times ----------------------------------------------------

  // Seek past the saved start time when a video begins playing
  applyStartTime(videoId) {
    const start = this.startStopTimesValue[videoId]?.start;
    if (!start || this.player.getCurrentTime() >= start) return;

    ahoy.track("video_start_time_applied", { ...this.getCurrentVideoInfo(), start_time: start });
    this.player.seekTo(start, true);
  }

  // The IFrame API has no "end time" event when playing a playlist, so poll for it
  startEndTimeCheck() {
    this.skippedAtEndTime = false;
    this.endTimeInterval = setInterval(() => this.checkEndTime(), 500);
  }

  stopEndTimeCheck() {
    if (this.endTimeInterval) {
      clearInterval(this.endTimeInterval);
      this.endTimeInterval = null;
    }
  }

  checkEndTime() {
    if (this.skippedAtEndTime || !this.player || typeof this.player.getPlayerState !== "function") return;
    if (this.player.getPlayerState() !== YT.PlayerState.PLAYING) return;

    const videoId = this.player.getVideoData()?.video_id;
    const end     = this.startStopTimesValue[videoId]?.end;
    if (!end || this.player.getCurrentTime() < end) return;

    this.skippedAtEndTime = true; // Reset when the next video starts playing
    ahoy.track("video_end_time_reached", { ...this.getCurrentVideoInfo(), end_time: end });
    this.lastKnownTime = null; // Same reason as in nextVideo()

    const playlist = this.player.getPlaylist() || [];
    if (this.player.getPlaylistIndex() >= playlist.length - 1) {
      this.player.stopVideo();
      this.onEnded();
    } else {
      this.player.nextVideo();
    }
  }

  // ---- Keyboard shortcuts -------------------------------------------------
  // Keys pressed while the YouTube iframe has focus go to YouTube, not to this page.

  handleKeydown(event) {
    if (event.ctrlKey || event.metaKey || event.altKey) return;

    const target = event.target;
    const isTyping = target.isContentEditable ||
      ["TEXTAREA", "SELECT"].includes(target.tagName) ||
      (target.tagName === "INPUT" && !["range", "checkbox", "button"].includes(target.type));
    if (isTyping) return;

    if (event.key === "Escape") {
      if (this.settingsOpen()) { this.closeSettings() }
      return;
    }

    const shortcuts = {
      "s": () => this.toggleSettings(),
      "f": () => this.toggleFocus(),
      "n": () => this.nextVideo(),
      "p": () => this.prevVideo(),
      " ": () => this.playPause()
    };
    const action = shortcuts[event.key.toLowerCase()];
    if (!action) return;

    // Also stops Space from scrolling the page or clicking the focused button
    event.preventDefault();
    if (event.repeat) return; // Holding a key down should not fire it over and over
    action();
  }

  // ---- Video settings card ------------------------------------------------

  settingsOpen() {
    return this.hasSettingsCardTarget && !this.settingsCardTarget.classList.contains("hidden");
  }

  toggleSettings() {
    this.settingsOpen() ? this.closeSettings() : this.openSettings();
  }

  openSettings() {
    this.settingsCardTarget.classList.remove("hidden");
    this.settingsButtonTarget.setAttribute("aria-expanded", "true");
    ahoy.track("video_settings_opened", this.player?.getVideoData?.() || {});

    if (this.populateSettingsCard()) { this.startSliderTarget.focus() }
  }

  closeSettings() {
    const hadFocus = this.settingsCardTarget.contains(document.activeElement);
    this.settingsCardTarget.classList.add("hidden");
    this.settingsButtonTarget.setAttribute("aria-expanded", "false");
    if (hadFocus) { this.settingsButtonTarget.focus() }
  }

  // Fill the card with the playing video's length and saved times. Returns false if no video is ready yet.
  populateSettingsCard() {
    const videoId  = this.player?.getVideoData?.()?.video_id;
    const duration = Math.floor(this.player?.getDuration?.() || 0);
    const sliders  = [this.startSliderTarget, this.endSliderTarget];

    if (!videoId || !duration) {
      this.settingsVideoId = null;
      sliders.forEach((slider) => { slider.disabled = true });
      this.saveButtonTarget.disabled = true;
      this.showSettingsStatus("Start playing a video, then open this again.");
      return false;
    }

    this.settingsVideoId  = videoId;
    this.settingsDuration = duration;
    sliders.forEach((slider) => { slider.disabled = false; slider.max = duration });
    this.saveButtonTarget.disabled = false;

    const saved = this.startStopTimesValue[videoId];
    this.endSliderTarget.value   = saved ? Math.min(saved.end, duration) : duration;
    this.startSliderTarget.value = saved ? Math.min(saved.start, this.endSliderTarget.value - 1) : 0;

    this.renderSettingsCard();
    this.showSettingsStatus(saved ? "Showing your saved times for this video." : "");
    return true;
  }

  renderSettingsCard() {
    const start     = Number(this.startSliderTarget.value);
    const end       = Number(this.endSliderTarget.value);
    const duration  = this.settingsDuration;
    const withHours = duration >= 3600;

    this.scaleMinTarget.textContent = this.formatTime(0, withHours);
    this.scaleMaxTarget.textContent = this.formatTime(duration, withHours);
    this.startOutputTarget.textContent = this.formatTime(start, withHours);
    this.endOutputTarget.textContent   = this.formatTime(end, withHours);
    this.startSliderTarget.setAttribute("aria-valuetext", this.formatTime(start, withHours));
    this.endSliderTarget.setAttribute("aria-valuetext", this.formatTime(end, withHours));

    this.rangeFillTarget.style.left  = `${(start / duration) * 100}%`;
    this.rangeFillTarget.style.width = `${((end - start) / duration) * 100}%`;
  }

  // Keep at least 1 second between start and end
  startSliderMoved() {
    const end = Number(this.endSliderTarget.value);
    if (Number(this.startSliderTarget.value) >= end) { this.startSliderTarget.value = end - 1 }
    this.settingsChanged();
  }

  endSliderMoved() {
    const start = Number(this.startSliderTarget.value);
    if (Number(this.endSliderTarget.value) <= start) { this.endSliderTarget.value = start + 1 }
    this.settingsChanged();
  }

  // Jump to the new start time so the user can hear where it begins
  previewStart() {
    if (this.settingsVideoId !== this.player.getVideoData()?.video_id) return;
    this.player.seekTo(Number(this.startSliderTarget.value), true);
  }

  setStartToNow() {
    if (!this.settingsVideoId) return;
    const now = Math.floor(this.player.getCurrentTime());
    this.startSliderTarget.value = Math.min(now, Number(this.endSliderTarget.value) - 1);
    this.settingsChanged();
  }

  setEndToNow() {
    if (!this.settingsVideoId) return;
    const now = Math.floor(this.player.getCurrentTime());
    this.endSliderTarget.value = Math.max(now, Number(this.startSliderTarget.value) + 1);
    this.settingsChanged();
  }

  settingsChanged() {
    this.renderSettingsCard();
    this.showSettingsStatus("Not saved yet.");
  }

  async saveSettings() {
    const videoId = this.settingsVideoId;
    if (!videoId) return;

    const start = Number(this.startSliderTarget.value);
    const end   = Number(this.endSliderTarget.value);
    if (start === 0 && end === this.settingsDuration) return this.resetSettings(); // Full video = nothing to save

    this.saveButtonTarget.disabled = true;
    try {
      const response = await this.sendVideoSetting("PUT", videoId, {
        video_setting: { setting_type: "start_stop_times", settings: { start, end } }
      });
      const body = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(body.errors?.join(", ") || `Server responded with ${response.status}`);

      this.startStopTimesValue = { ...this.startStopTimesValue, [videoId]: body.settings };
      const withHours = this.settingsDuration >= 3600;
      this.showSettingsStatus(`Saved. This video will play from ${this.formatTime(start, withHours)} to ${this.formatTime(end, withHours)}.`);

      if (videoId === this.player.getVideoData()?.video_id) { this.applyStartTime(videoId) }
    } catch (error) {
      console.error("Could not save video settings:", error);
      this.showSettingsStatus(`Could not save: ${error.message}`, true);
    } finally {
      this.saveButtonTarget.disabled = false;
    }
  }

  async resetSettings() {
    const videoId = this.settingsVideoId;
    if (!videoId) return;

    this.startSliderTarget.value = 0;
    this.endSliderTarget.value   = this.settingsDuration;
    this.renderSettingsCard();

    if (!this.startStopTimesValue[videoId]) {
      this.showSettingsStatus("This video will play in full.");
      return;
    }

    try {
      const response = await this.sendVideoSetting("DELETE", videoId);
      if (!response.ok) throw new Error(`Server responded with ${response.status}`);

      const { [videoId]: _removed, ...remaining } = this.startStopTimesValue;
      this.startStopTimesValue = remaining;
      this.showSettingsStatus("This video will play in full.");
    } catch (error) {
      console.error("Could not reset video settings:", error);
      this.showSettingsStatus(`Could not reset: ${error.message}`, true);
    }
  }

  sendVideoSetting(method, videoId, body = null) {
    const query = method === "DELETE" ? "?setting_type=start_stop_times" : "";
    return fetch(`/video-settings/${encodeURIComponent(videoId)}${query}`, {
      method,
      headers: {
        "Content-Type": "application/json",
        "Accept":       "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: body ? JSON.stringify(body) : null
    });
  }

  showSettingsStatus(message, isError = false) {
    this.settingsStatusTarget.textContent = message;
    this.settingsStatusTarget.classList.toggle("error", isError);
  }

  // 76 minutes => "01:16:00"; 4 minutes 5 seconds => "04:05"
  formatTime(totalSeconds, withHours) {
    const pad     = (n) => String(n).padStart(2, "0");
    const hours   = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = Math.floor(totalSeconds % 60);
    return withHours ? `${pad(hours)}:${pad(minutes)}:${pad(seconds)}` : `${pad(minutes)}:${pad(seconds)}`;
  }

  // Dynamically load the YouTube IFrame API
  loadYouTubeAPI() {
    return new Promise((resolve) => {
      // If API already loaded, resolve immediately
      if (window.YT && window.YT.Player) {
        resolve()
        return
      }

      // If API is loading, attach another resolver
      if (window._ytReadyResolvers) {
        window._ytReadyResolvers.push(resolve)
        return
      }

      // Initialize global resolvers list and callback
      window._ytReadyResolvers = [resolve]
      window.onYouTubeIframeAPIReady = () => {
        window._ytReadyResolvers.forEach((r) => r())
        window._ytReadyResolvers = []
      }

      // Dynamically inject the YouTube script
      const tag = document.createElement("script")
      tag.src = "https://www.youtube.com/iframe_api"
      document.head.appendChild(tag)
    })
  }

  getCurrentVideoInfo() {
    return this.player.getVideoData();
  }
}