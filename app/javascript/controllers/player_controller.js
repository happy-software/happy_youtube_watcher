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
      // Show warning, hide player
      this.mobileWarningTarget.classList.remove("hidden");
      this.playerContainerTarget.classList.add("hidden");
      return; // Don’t initialize the player
    }

    this.focusMode = window.innerWidth <= 768 ? true : this.defaultFocusModeValue;
    this.applyFocusMode();

    this.retryInitializingYtPlayer();
  }

  initPlayer() {
    this.currentIndex = 0;

    this.player = new YT.Player("player-container", {
      height: "390",
      width: "640",
      videoId: this.videoIdsValue[this.currentIndex],
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
  }

  toggleFocus() {
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
      this.player.pauseVideo();
    } else {
      this.player.playVideo();
    }
  }

  nextVideo() {
    this.player.nextVideo();
  }

  prevVideo() {
    this.player.previousVideo();
  }

  repeatVideo() {
    const current = this.player.getVideoUrl();
    this.player.seekTo(0)
    this.player.playVideo();
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

  onError() {
    console.log("OnError triggered for:", this.player.getVideoData());
    this.player.nextVideo();
  }

  onEnded() {
    // Need to load the next set of shuffled videos from the playlist(s) here
    // TODO: Looks like onEnded() gets called when users manually select another video in the playlist, so we need to handle that case too
    console.log("Playlist ended, refresh the page. We haven't implemented an auto fetch yet.")
    location.reload();
  }

  onReady() {
    window.player = this.player;
    this.updateTitle(); // Set title when ready
    console.log("Player is ready!");
  }

  onStateChange(event) {
    // https://web.archive.org/web/20250727111728/https://developers.google.com/youtube/iframe_api_reference#Playback_status
    switch(event.data) {
      // Possible states:
      // YT.PlayerState.PAUSED
      // YT.PlayerState.BUFFERING
      // YT.PlayerState.CUED
      case YT.PlayerState.UNSTARTED:
        if (this.player.getVideoData().errorCode) {
          // NOTE: This gets called AFTER the onError() triggers
          console.log("Video is unstarted with error:", this.player.getVideoData());
        }
        break;
      case YT.PlayerState.ENDED:
        this.onEnded();
        break;
      case YT.PlayerState.PLAYING:
        this.updateTitle(); // Update title on play
        break;
    }
  }

  async retryInitializingYtPlayer() {
    let attempts = 0;
    let maxAttempts = 10;

    this.initPlayer();

    while(attempts < maxAttempts && !(window.YT && window.YT.Player)) {
      setTimeout(function() { console.log(`(${attempts}/${maxAttempts}) Couldn't load player, trying again...`)}, 500);
      attempts++;
      this.initPlayer();
    }
  }

}