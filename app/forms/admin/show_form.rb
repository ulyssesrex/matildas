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

    attr_accessor :link_ids, :new_venue, :new_links
    attr_reader :show

    validates :date, :time, :price, presence: true
    validate :date_is_valid
    validate :time_is_valid
    validate :venue_choice_is_valid
    validate :existing_link_ids_are_valid
    validate :new_link_rows_are_complete

    def initialize(attributes = {})
      super
      self.link_ids ||= []
      self.new_venue ||= {}
      self.new_links ||= {}
    end

    def save
      return false unless valid?

      ApplicationRecord.transaction do
        venue = existing_venue || create_new_venue
        @show = Show.create!(time: parsed_time, price: price, venue: venue)
        @show.links = existing_links
        normalized_new_links.each { |link_attributes| @show.links << Link.create!(link_attributes) }
      end

      true
    rescue ActiveRecord::RecordInvalid => error
      message = error.record.errors.full_messages.to_sentence.presence || "Submission could not be saved"
      errors.add(:base, message)
      false
    end

    def submitted_new_links
      rows = normalized_hash(new_links).values.map { |row| normalized_hash(row).slice("name", "url") }
      rows.presence || [ { "name" => "", "url" => "" } ]
    end

    private

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
        return unless parsed_date && parsed_time_parts

        Time.use_zone("Eastern Time (US & Canada)") do
          Time.zone.local(parsed_date.year, parsed_date.month, parsed_date.day, *parsed_time_parts)
        end
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

      def existing_link_ids_are_valid
        return if normalized_link_ids.empty?

        errors.add(:link_ids, "contain an invalid Link") unless existing_links.length == normalized_link_ids.length
      end

      def new_link_rows_are_complete
        submitted_new_links.each_with_index do |row, index|
          next if row.values.all?(&:blank?)

          errors.add(:new_links, "row #{index + 1} Name can't be blank") if row["name"].blank?
          errors.add(:new_links, "row #{index + 1} URL can't be blank") if row["url"].blank?
        end
      end

      def existing_venue
        return if venue_id.blank?

        @existing_venue ||= Venue.find_by(id: venue_id)
      end

      def existing_links
        @existing_links ||= Link.where(id: normalized_link_ids).to_a
      end

      def normalized_link_ids
        @normalized_link_ids ||= Array(link_ids).reject(&:blank?).map(&:to_s).uniq
      end

      def normalized_new_venue
        @normalized_new_venue ||= normalized_hash(new_venue).slice(*VENUE_FIELDS)
      end

      def new_venue_started?
        normalized_new_venue.values.any?(&:present?)
      end

      def normalized_new_links
        submitted_new_links.filter_map do |row|
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
