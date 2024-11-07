namespace :backpop_playlist_deltas do
  desc 'Run a one-time job to back pop PlaylistSnapshot diffs into PlaylistDelta records'
  task :run => :environment do
    start_time = Time.now
    puts "Started at #{start_time}"
    PlaylistSnapshot.all.each do |snapshot|
      next if snapshot.playlist_delta.present?

      previous_snapshot = PlaylistSnapshot.where(playlist_id: snapshot.tracked_playlist.playlist_id).where("created_at < ?", snapshot.created_at).newest
      next unless previous_snapshot.present?

      current_playlist_items  = snapshot.playlist_items
      previous_playlist_items = PlaylistSnapshot.get_working_songs(previous_snapshot.playlist_items)
      diff                    = PlaylistDifferenceCalculator.calculate_diffs(current_playlist_items, previous_playlist_items)
      next unless diff.any_changes?

      PlaylistDelta.create!(
        added:             diff.added_songs,
        removed:           diff.removed_songs,
        playlist_snapshot: snapshot,
        tracked_playlist:  snapshot.tracked_playlist,
      )
    end

    finish_time = Time.now
    puts "Finished at: #{finish_time}"
    puts "Total Runtime: #{finish_time - start_time}s"
  end
end