# require 'offsite_payments/integrations/u_b_l/helper'
# require 'offsite_payments/integrations/u_b_l/notification'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module UBL

      module_function

      mattr_accessor :service_url
       #self.service_url = 'https://demo-ipg.comtrust.ae/SPIless/Registration.aspx'

      # def logger
      #   @logger = Logger.new()
      # end

      def transaction_for_registration

        @transaction_for_registration ||= begin

          require 'rjb'
          Rjb::load

          transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction")

          transaction = transaction_class.new("#{Rails.root}/config/SPI.properties")

          transaction.initialize('Registration',"1.0")

          transaction.setProperty("Channel", 'Web')
          transaction.setProperty("Amount", @payment_amount.to_s)
          transaction.setProperty("Currency", @payment_currency.to_s)
          transaction.setProperty("OrderID", "#{@order_id}")
          transaction.setProperty("TransactionHint", "CPT:Y;VCC:Y")
          transaction.setProperty("ReturnPath", @return_path)
          transaction.setProperty("OrderName", @order_name.to_s)


          # logger.error("Customer: #{transaction.getProperty('Customer')}")
          # #logger.error("Store: #{transaction.getProperty('Store')}")
          # #logger.error("Terminal: #{transaction.getProperty('Terminal')}")
          # logger.error("Channel: #{transaction.getProperty('Channel')}")
          # logger.error("Amount: #{transaction.getProperty('Amount')}")
          # logger.error("Currency: #{transaction.getProperty('Currency')}")
          # logger.error("OrderName: #{transaction.getProperty('OrderName')}")
          # logger.error("OrderInfo: #{transaction.getProperty('OrderInfo')}")
          # logger.error("OrderID: #{transaction.getProperty('OrderID')}")
          # logger.error("TransactionHint: #{transaction.getProperty('TransactionHint')}")
          # logger.error("ReturnPath: #{return_path}")

          result = transaction.execute()

          transaction


        end
      end

      def transaction_for_registration_response_code
        @transaction_for_registration_response_code ||= transaction_for_registration.getResponseCode
      end

      def transaction_for_registration_response_description
        @transaction_for_registration_response_description ||= transaction_for_registration.getResponseDescription
      end

      def errors
        @error ||= []
      end

      def transaction_for_registration_transaction_id
        @transaction_for_registration_transaction_id ||= transaction_for_registration.getProperty('TransactionID')

        # '1222'
      end

      def service_url
        @service_url ||= transaction_for_registration.getProperty('PaymentPage')
        # @service_url ||= 'www.Testadsfadfadsfasd.com'

      end

      def process_transaction_for_registration(payment_amount, payment_currency, order_id, return_path, order_name)
        @transaction_for_registration = nil

        @payment_amount = payment_amount
        @payment_currency = payment_currency
        @order_id = order_id
        @return_path = return_path
        @order_name = order_name

        transaction_for_registration

        if transaction_for_registration_response_code.to_i > 0
          errors << "#{@transaction_for_registration_response_code}: #{transaction_for_registration_response_description}"
          errors << "For more information, please contact your card issuing bank."
          service_url
          false
        else
          service_url
          true
        end
      end

      def transaction_for_finalization

        @transaction_for_finalization ||= begin

          require 'rjb'
          Rjb::load
          transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

          finalization = transaction_class.new("#{Rails.root}/config/SPI.properties");
          finalization.initialize('Finalization',"1.0");

          finalization.setProperty("TransactionID", @transaction_id.to_s)

          result = finalization.execute()

          finalization

        end
      end

      def transaction_for_finalization_response_code
        @transaction_for_finalization_response_code ||= transaction_for_finalization.getResponseCode
      end

      def transaction_for_finalization_response_description
        @transaction_for_finalization_response_description ||= transaction_for_finalization.getResponseDescription
      end

      def transaction_for_finalization_approval_code
        @transaction_for_finalization_approval_code ||= transaction_for_finalization.getProperty('ApprovalCode')
      end

      def transaction_for_finalization_order_id
        @transaction_for_finalization_order_id ||= transaction_for_finalization.getProperty('OrderID')
      end

      def transaction_for_finalization_amount
        @transaction_for_finalization_amount ||= transaction_for_finalization.getProperty('Amount')
      end

      def transaction_for_finalization_balance
        @transaction_for_finalization_balance ||= transaction_for_finalization.getProperty('Balance')
      end

      def transaction_for_finalization_card_number
        @transaction_for_finalization_card_number ||= transaction_for_finalization.getProperty('CardNumber')
      end

      def transaction_for_finalization_card_token
        @transaction_for_finalization_card_token ||= transaction_for_finalization.getProperty('CardToken')
      end

      def transaction_for_finalization_account
        @transaction_for_finalization_account ||= transaction_for_finalization.getProperty('Account')
      end


      def process_transaction_for_finalization(transaction_id)
        @transaction_for_registration = nil

        @transaction_id = transaction_id

        transaction_for_finalization

        if transaction_for_finalization_response_code.to_i > 0
          errors << "#{@transaction_for_finalization_response_code}: #{transaction_for_finalization_response_description}"
          errors << "For more information, please contact your card issuing bank."
          false
        else
          true
        end
      end

      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper

        #SERVICE_URL = 'https://www.onlinepayment.com.my/MOLPay/pay/'


        # def form_method
        #   "GET"
        # end

        def credential_based_url

          service_url = UBL.service_url

          service_url

        end


        def initialize(order, account, options = {})
          super
          add_field('TransactionID', '12')
          add_field('Style', 'STL:18')
        end

        # Replace with the real mapping


        # mapping :account, 'Customer'
        # mapping :amount, 'Amount'
        # mapping :currency, 'Currency'
         mapping :order, 'TransactionID'
        # mapping :description, 'OrderInfo'
        # mapping :return_url, 'ReturnPath'
        # mapping :notify_url, ''
        # mapping :cancel_return_url, ''


        # mapping :customer, :first_name => '',
        #                    :last_name  => '',
        #                    :email      => '',
        #                    :phone      => ''
        #
        # mapping :billing_address, :city     => '',
        #                           :address1 => '',
        #                           :address2 => '',
        #                           :state    => '',
        #                           :zip      => '',
        #                           :country  => ''
        #
        # mapping :tax, ''
        # mapping :shipping, ''
      end

      class Notification < OffsitePayments::Notification


        def complete?
          params['']
        end

        def item_id
          params['']
        end

        def ResponseCode
          params[:ResponseCode]
        end

        def ResponseClass
          params[:ResponseClass]
        end

        def ResponseClassDescription
          params[:ResponseClassDescription]
        end

        def PaymentPage
          params[:PaymentPage]
        end

        def ApprovalCode
          params[:ApprovalCode]
        end

        def OrderID
          params[:OrderID]
        end

        def ResponseDescription
          params[:ResponseDescription]
        end

        def approval_code
          params[:ApprovalCode]
        end

        def transaction_id
          params[:TransactionID]
        end

        # When was this payment received by the client.
        def received_at
          params['']
        end

        def payer_email
          params['']
        end

        def receiver_email
          params['']
        end

        def security_key
          params['']
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['']
        end

        # Was this a test transaction?
        def test?
          params[''] == 'test'
        end

        def status
          params['']
        end

        # Acknowledge the transaction to UBL. This method has to be called after a new
        # apc arrives. UBL will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def ipn
        #     notify = UBLNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)
          payload = raw

          uri = URI.parse(UBL.notification_confirmation_url)

          request = Net::HTTP::Post.new(uri.path)

          request['Content-Length'] = "#{payload.size}"
          request['User-Agent'] = "Active Merchant -- http://activemerchant.org/"
          request['Content-Type'] = "application/x-www-form-urlencoded"

          http = Net::HTTP.new(uri.host, uri.port)
          http.verify_mode    = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
          http.use_ssl        = true

          response = http.request(request, payload)

          # Replace with the appropriate codes
          raise StandardError.new("Faulty UBL result: #{response.body}") unless ["AUTHORISED", "DECLINED"].include?(response.body)
          response.body == "AUTHORISED"
        end

        private

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post.to_s
          for line in @raw.split('&')
            key, value = *line.scan( %r{^([A-Za-z0-9_.-]+)\=(.*)$} ).flatten
            params[key] = CGI.unescape(value.to_s) if key.present?
          end
        end
      end



    end
  end
end
