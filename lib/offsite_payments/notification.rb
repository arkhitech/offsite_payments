module OffsitePayments #:nodoc:
  class Notification
    attr_accessor :params

    # set this to an array in the subclass, to specify which IPs are allowed
    # to send requests
    class_attribute :production_ips

    # * *Args*    :
    #   - +doc+ ->     raw post string
    #   - +options+ -> custom options which individual implementations can
    #                  utilize
    def initialize(params, options = {})
      @options = options
      self.params = params
      empty!
    end

    def status
      raise NotImplementedError, "Must implement this method in the subclass"
    end

    # the money amount we received in X.2 decimal.
    def gross
      raise NotImplementedError, "Must implement this method in the subclass"
    end

    def gross_cents
      (gross.to_f * 100.0).round
    end

    # This combines the gross and currency and returns a proper Money object.
    # this requires the money library located at http://rubymoney.github.io/money/
    def amount
      return Money.new(gross_cents, currency) rescue ArgumentError
      return Money.new(gross_cents) # maybe you have an own money object which doesn't take a currency?
    end

    # reset the notification.
    def empty!
      @params  = Hash.new
      @raw     = ""
    end

    # Check if the request comes from an official IP
    def valid_sender?(ip)
      return true if OffsitePayments.mode == :test || production_ips.blank?
      production_ips.include?(ip)
    end

    def test?
      false
    end

    def iso_currency
      ActiveUtils::CurrencyCode.standardize(currency)
    end

  end
end
