module Admin
  class ShowForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    VENUE_FIELDS = %w[name city state map_url].freeze
    TIME_PATTERN = /\A(?<hour>\d{1,2}):(?<minute>\d{2})\z/

    attribute :date, :string
    attribute :time, :string
    attribute :price, :string
    attribute :venue_id, :string
    attribute :cancelled, :boolean, default: false
    attribute :notes, :string
    attribute :cancellation_notes, :string

    attr_accessor :artist_ids, :new_venue, :new_artists
    attr_reader :show

    validates :date, :price, presence: true
    validate :date_is_valid
    validate :time_is_valid
    validate :venue_choice_is_valid
    validate :existing_artist_ids_are_valid
    validate :new_artist_rows_are_complete

    def initialize(attributes = {})
      attributes = attributes.to_h
      @show = attributes.delete(:show) || attributes.delete("show")
      attributes = attributes_from_show if attributes.empty?

      super(attributes)
      self.artist_ids ||= []
      self.new_venue ||= {}
      self.new_artists ||= {}
    end

    def save
      return false unless valid?

      ApplicationRecord.transaction do
        venue = existing_venue || create_new_venue
        @show ||= Show.new
        @show.update!(
          date: parsed_date,
          time: parsed_time,
          price: price,
          venue: venue,
          cancelled: cancelled,
          notes: notes,
          cancellation_notes: cancellation_notes
        )
        @show.artists = existing_artists
        normalized_new_artists.each { |artist_attributes| @show.artists << Artist.create!(artist_attributes) }
      end

      true
    rescue ActiveRecord::RecordInvalid => error
      message = error.record.errors.full_messages.to_sentence.presence || "Submission could not be saved"
      errors.add(:base, message)
      false
    end

    def submitted_new_artists
      rows = normalized_hash(new_artists).values.map { |row| normalized_hash(row).slice("name", "url") }
      rows.presence || [ { "name" => "", "url" => "" } ]
    end

    private

      def attributes_from_show
        return {} unless show

        {
          date: show.date&.iso8601,
          time: show.time&.strftime("%H:%M"),
          price: show.price,
          venue_id: show.venue_id&.to_s,
          artist_ids: show.artist_ids.map(&:to_s),
          cancelled: show.cancelled,
          notes: show.notes,
          cancellation_notes: show.cancellation_notes
        }
      end

      def parsed_date
        @parsed_date ||= Date.iso8601(date.to_s)
      end

      def parsed_time_parts
        return @parsed_time_parts if defined?(@parsed_time_parts)

        match = TIME_PATTERN.match(time.to_s)
        @parsed_time_parts = if match && match[:hour].to_i.between?(0, 23) && match[:minute].to_i.between?(0, 59)
          [ match[:hour].to_i, match[:minute].to_i ]
        end
      end

      def parsed_time
        return if time.blank? || parsed_time_parts.nil?

        Time.zone.local(2000, 1, 1, *parsed_time_parts)
      end

      def date_is_valid
        parsed_date if date.present?
      rescue Date::Error
        errors.add(:date, "is invalid")
      end

      def time_is_valid
        errors.add(:time, "is invalid") if time.present? && parsed_time_parts.nil?
      end

      def venue_choice_is_valid
        if venue_id.present? && new_venue_started?
          errors.add(:venue, "choose an existing venue or create a new venue, not both")
        elsif venue_id.present? && existing_venue.nil?
          errors.add(:venue_id, "is invalid")
        elsif new_venue_started?
          VENUE_FIELDS.each do |field|
            errors.add("new_venue_#{field}", "can't be blank") if normalized_new_venue[field].blank?
          end
        end
      end

      def existing_artist_ids_are_valid
        return if normalized_artist_ids.empty?

        errors.add(:artist_ids, "contain an invalid Artist") unless existing_artists.length == normalized_artist_ids.length
      end

      def new_artist_rows_are_complete
        submitted_new_artists.each_with_index do |row, index|
          next if row.values.all?(&:blank?)

          errors.add(:new_artists, "row #{index + 1} Name can't be blank") if row["name"].blank?
          errors.add(:new_artists, "row #{index + 1} URL can't be blank") if row["url"].blank?
        end
      end

      def existing_venue
        return if venue_id.blank?

        @existing_venue ||= Venue.find_by(id: venue_id)
      end

      def existing_artists
        @existing_artists ||= Artist.where(id: normalized_artist_ids).to_a
      end

      def normalized_artist_ids
        @normalized_artist_ids ||= Array(artist_ids).reject(&:blank?).map(&:to_s).uniq
      end

      def normalized_new_venue
        @normalized_new_venue ||= normalized_hash(new_venue).slice(*VENUE_FIELDS)
      end

      def new_venue_started?
        normalized_new_venue.values.any?(&:present?)
      end

      def normalized_new_artists
        submitted_new_artists.filter_map do |row|
          row.symbolize_keys if row.values.any?(&:present?)
        end
      end

      def create_new_venue
        Venue.create!(normalized_new_venue) if new_venue_started?
      end

      def normalized_hash(value)
        value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
        value.to_h.stringify_keys
      end
  end
end
