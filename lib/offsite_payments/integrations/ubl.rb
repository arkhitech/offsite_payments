# require 'offsite_payments/integrations/ubl/helper'
# require 'offsite_payments/integrations/ubl/notification'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Ubl

      module_function

      mattr_accessor :service_url
      #self.service_url = 'https://demo-ipg.comtrust.ae/SPIless/Registration.aspx'

      # def logger
      #   @logger = Logger.new()
      # end
      def self.service_url
        notification.transaction_for_registration.getProperty('PaymentPage')
        # @service_url ||= 'www.Testadsfadfadsfasd.com'
      end
      
      def self.notification(post = {})
        Notification.new(post)
      end
      
      
#      def initialize(options = {})
#        #requires!(options, :spi_config_file_path)
#        super
#      end
      
      def purchase
        raise 'Purchase not implemented as it is done offline'
      end
      
      def authorize
        raise 'Authorize not implemented as it is done offline'
      end
      
      def capture(money, authorization, options = {})
        notification.process_transaction_for_capture(authorization, money.amount, options[:currency] || 'PKR')
      end
      def cancel(money, authorization, options = {})
        notification.process_transaction_for_reversal(authorization, money.amount, options[:currency] || 'PKR')
      end
      def void(authorization, options = {})
        notification.process_transaction_for_refund(authorization)
      end
      
      def errors
        notification.errors
      end
      
      def notification
        @notification ||= Notification.new({})
      end
      private :notification
      
      def transaction_for_finalization_order_id
        notification.transaction_for_finalization_order_id
      end
      
      def transaction_for_registration_transaction_id
        notification.transaction_for_registration_transaction_id
      end
      
      def process_transaction_for_registration(payment_amount, payment_currency, order_id, return_path, order_name, auto_capture)
        notification.process_transaction_for_registration(payment_amount, payment_currency, order_id, return_path, order_name, auto_capture)
      end


      class Helper < OffsitePayments::Helper

        #SERVICE_URL = 'https://www.onlinepayment.com.my/MOLPay/pay/'


        # def form_method
        #   "GET"
        # end

        def credential_based_url
          notification.service_url
        end
        attr_accessor :errors

        def initialize(order, account, options = {})   
          super          
          transaction = notification.process_transaction_for_registration(options[:amount], 
            options[:currency],  "#{order}", options[:return_url], account, options[:auto_capture])
          if transaction
            add_field('TransactionID', notification.transaction_for_registration_transaction_id)
            add_field('Style', 'STL:18')
          else            
            #TODO should not auto submit but show error here
            self.errors = notification.errors
          end
        end        
        def notification
          @notification ||= Notification.new({})
        end
        private :notification

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

        def response_code
          transaction_for_finalization_response_code
        end


        def service_url
          @service_url ||= transaction_for_registration.getProperty('PaymentPage')
          # @service_url ||= 'www.Testadsfadfadsfasd.com'

        end
        def payment_page
          service_url
        end

        def approval_code
          transaction_for_finalization_approval_code
        end

        def order_id
          transaction_for_finalization_order_id
        end

        def response_description
          transaction_for_finalization_response_description
        end

        def approval_code
          transaction_for_finalization_approval_code
        end

        def authorization
          transaction_id
        end
        def avs_result
          {}
        end
        def cvv_result
          nil
        end
        def transaction_id=(transaction_id)
          params[:TransactionID] = params[:transaction_id] = transaction_id
        end
        def transaction_id
          params[:TransactionID] || params[:transaction_id]
        end

        def currency=(currency)
          @currency = currency
        end
        def currency
          @currency
        end
        def amount=(amount)
          @amount = amount
        end
        def amount
          @amount
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
          amount.amount.to_f
        end
        

        # Was this a test transaction?
        def test?
          params[''] == 'test'
        end

        def status
          transaction_for_finalization_response_code
        end

        def success?
          errors.empty?
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
          process_transaction_for_finalization(transaction_id)
        end

        def process_transaction_for_refund(transaction_id)
          self.transaction_id = transaction_id
          response = transaction_for_refund
          response_code = transaction_for_registration.getResponseCode.to_i
          if response_code > 0
            errors << "#{response_code}: #{response.getResponseDescription}"
            errors << "For more information, please contact your card issuing bank."
          else
            true
          end
        end
        
        def process_transaction_for_reversal(transaction_id, amount, currency)
          self.transaction_id = transaction_id
          response = transaction_for_reversal(amount, currency)
          if transaction_id.to_s != response.getProperty('TransactionID')
            errors << "Capture was unsuccessful - No transaction id returned from gateway"
          else
            self.amount = Money.new(amount * 100, currency)
            true
          end
        end
        
        def process_transaction_for_capture(transaction_id, amount, currency)
          self.transaction_id = transaction_id
          response = transaction_for_capture(amount, currency)
          if transaction_id.to_s != response.getProperty('TransactionID')
            errors << "Capture was unsuccessful - No transaction id returned from gateway"
          else
            self.amount = Money.new(amount * 100, currency)
            true
          end
        end
        
        def process_transaction_for_registration(payment_amount, payment_currency, order_id, return_path, order_name, auto_capture)
          @transaction_for_registration = nil

          @payment_amount = payment_amount
          @payment_currency = payment_currency
          @order_id = order_id
          @return_path = return_path
          @order_name = order_name

          transaction_for_registration(auto_capture)

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
      
        def transaction_for_registration_transaction_id
          @transaction_for_registration_transaction_id ||= transaction_for_registration.getProperty('TransactionID')

          # '1222'
        end
        
        def errors
          @error ||= []
        end
      
        def transaction_for_registration(auto_capture = true)
          @transaction_for_registration ||= begin

            properties = {
              "TransactionID" => @transaction_id.to_s,
              "Channel" => 'Web',
              "Amount" => @payment_amount.to_s,
              "Currency" => @payment_currency.to_s,
              "OrderID" => "#{@order_id}",
              "TransactionHint" => (auto_capture ? "CPT:Y;VCC:Y" : "CPT:N;VCC:Y"),
              "ReturnPath" => @return_path,
              "OrderName" => @order_name.to_s                            
            }
            execute_transaction('Registration', properties, '1.0')            
          end
        end
        
        def transaction_for_finalization
          @transaction_for_finalization ||= begin
            properties = {
              "TransactionID" => @transaction_id.to_s,
              "Channel" => 'Web'
            }
            execute_transaction('Finalization', properties, '1.0')
          end
        end

        def transaction_for_reversal(amount = nil, currency = nil)
          @transaction_for_reversal ||= begin
            
            properties = {
              "TransactionID" => @transaction_id.to_s,
              "Channel" => 'Web'
            }
            properties['Amount'] = amount.to_s if amount
            properties['Currency'] = currency.to_s if currency
            
            execute_transaction('Reversal', properties, '1.0')
          end          
        end
        
        def transaction_for_capture(amount = nil, currency = nil)
          @transaction_for_capture ||= begin
            properties = {
              "TransactionID" => @transaction_id.to_s,
              "Channel" => 'Web'
            }
            properties['Amount'] = amount.to_s if amount
            properties['Currency'] = currency.to_s if currency
            execute_transaction('Capture', properties, '1.0')
          end          
        end

        def transaction_for_refund
          @transaction_for_capture ||= begin
            properties = {
              "TransactionID" => @transaction_id.to_s,
              "Channel" => 'Web'
            }
            execute_transaction('Refund', properties, '1.0')
          end          
        end
        
        private
      

        def transaction_for_registration_response_code
          @transaction_for_registration_response_code ||= transaction_for_registration.getResponseCode
        end

        def transaction_for_registration_response_description
          @transaction_for_registration_response_description ||= transaction_for_registration.getResponseDescription
        end
        
        def execute_transaction(transaction_name, properties, version = '1.0')
          require 'rjb'
          Rjb::load
          transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

          transaction = transaction_class.new("#{Rails.root}/config/SPI.properties");
          transaction.initialize(transaction_name, version);

          properties.each_pair do |k, v|
            transaction.setProperty(k, v)
          end

          result = transaction.execute()

          transaction          
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

        def transaction_for_finalization_currency
          @transaction_for_finalization_currency ||= transaction_for_finalization.getProperty('Currency')
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
            self.amount = Money.new(transaction_for_finalization_amount.to_f * 100)
            true
          end
        end
        
        # Take the posted data and move the relevant data into a hash
        def parse(post)
          case post
          when Hash
            post.each_pair do |k, v|
              params[k.to_sym] = v
            end
          else
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
end
