import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    videoIds: Array,
    defaultFocusMode: Boolean
  }

  static targets = ["playerContainer", "focusControls", "focusToggle", "mobileWarning"]

  connect() {
    window.playerController = this;

    // Detect mobile browsers (simple heuristic: screen width + user agent)
    const isMobile = /Mobi|Android/i.test(navigator.userAgent);

    if (isMobile) {
      ahoy.track("mobile_warning_displayed", { user_agent: navigator.userAgent});
      // Show warning, hide player
      this.mobileWarningTarget.classList.remove("hidden");
      this.playerContainerTarget.classList.add("hidden");
      return; // Don’t initialize the player
    }

    this.focusMode = window.innerWidth <= 768 ? true : this.defaultFocusModeValue;
    this.applyFocusMode();

    this.loadYouTubeAPI().then(() => this.initPlayer());
  }

  disconnect() {
    this.stopWatchdog();
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
    ahoy.track("player_initialized", {video_ids: this.videoIdsValue});
  }

  toggleFocus() {
    ahoy.track("toggle_focus", {current_mode_before_toggle: this.focusMode});
    this.focusMode = !this.focusMode;
    this.applyFocusMode();
  }

  applyFocusMode() {
    if (this.focusMode) {
      this.element.classList.add("focus-mode");
      this.focusControlsTarget.classList.remove("hidden");

      if (this.hasFocusToggleTarget) { this.focusToggleTarget.checked = true }
    } else {
      this.element.classList.remove("focus-mode");
      if (window.innerWidth > 768) {
        this.focusControlsTarget.classList.add("hidden");
      }

      if (this.hasFocusToggleTarget) { this.focusToggleTarget.checked = false }
    }
  }

  playPause() {
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
    ahoy.track("next_button_pushed", this.getCurrentVideoInfo());
    this.player.nextVideo();
  }

  prevVideo() {
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
      const videoTitleElement = document.getElementById("video-title");
      videoTitleElement.innerText = videoData.title;
    } else {
      document.title = "YouTube Player";
    }
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
    // Need to load the next set of shuffled videos from the playlist(s) here
    // TODO: Looks like onEnded() gets called when users manually select another video in the playlist, so we need to handle that case too
    console.log("Playlist ended, refresh the page. We haven't implemented an auto fetch yet.")
    location.reload();
  }

  onReady() {
    window.player = this.player;
    this.updateTitle(); // Set title when ready
    this.startWatchdog();
    console.log("Player is ready!");
  }

  startWatchdog() {
    this.lastKnownTime = null;
    this.bufferingStartedAt = null;
    this.playerStartedAt = Date.now();
    this.videosPlayedCount = 0;
    this.lastPlayingVideoId = null;
    this.watchdogInterval = setInterval(() => this.checkPlayerHealth(), 15000);
  }

  stopWatchdog() {
    if (this.watchdogInterval) {
      clearInterval(this.watchdogInterval);
      this.watchdogInterval = null;
    }
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
        }
        break;
      }
    }
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