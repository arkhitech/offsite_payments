module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module JazzCash
      #JazzCash Integration for HTTP Redirect v1.1

      def self.notification(post, options = {})
        Notification.new(post)
      end

      def self.return(query_string, options = {})
        Return.new(query_string)
      end

      class Helper < OffsitePayments::Helper
        attr_accessor :salt
        attr_accessor :valid_till

        def credential_based_url
          unless test?
            'https://payments.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform'
          else
            "https://sandbox.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform"
          end
        end

        def initialize(order, account, options = {})
          super
        end

        mapping :order, 'pp_TxnRefNo'
        mapping :account, 'pp_MerchantID'
        mapping :amount, 'pp_Amount'
        mapping :currency, 'pp_TxnCurrency'
        mapping :credential2, 'pp_Password'
        mapping :return_url, 'pp_ReturnURL'

        def transaction_time
          @transaction_time ||= Time.now
        end
            
        def pp_TxnDateTime
          transaction_time.strftime("%Y%m%d%H%M%S")
        end
      
        def pp_TxnExpiryDateTime
          valid_till.strftime("%Y%m%d%H%M%S")
        end
      
        def secure_hash          
          hash_items = [salt]
          fields.keys.sort.each do |key|
            if key =~ /\App(_|m)/
              hash_items << fields[key]
            end
          end
          OpenSSL::HMAC.hexdigest('SHA256', salt, hash_items.join('&')).upcase
        end

        def form_fields
          raise 'salt is not set' unless salt

          self.add_field('pp_TxnDateTime', pp_TxnDateTime)
          self.add_field('pp_TxnExpiryDateTime', pp_TxnExpiryDateTime)  if valid_till    
          self.add_field('pp_SecureHash', secure_hash)

          self.fields.assert_valid_keys(%w(pp_ReturnURL pp_Version pp_Language pp_BankID pp_ProductID 
            pp_IsRegisteredCustomer pp_CustomerID pp_CustomerEmail pp_CustomerMobile 
            pp_TxnType pp_TxnRefNo pp_MerchantID pp_SubMerchantID pp_Password pp_Amount pp_TxnCurrency 
            pp_TxnDateTime pp_TxnExpiryDateTime pp_BillReference pp_Description pp_CustomerCardNumber 
            pp_CustomerCardExpiry pp_CustomerCardCvv pp_SecureHash pp_DiscountedAmount pp_DiscountBank
            ppmpf_1 ppmpf_2 ppmpf_3 ppmpf_4 ppmpf_5
            ))
          super
        end
      end
      
      class Notification < OffsitePayments::Notification
        include ActiveUtils::PostsData

        # "summaryStatus":"CARD_NOT_ENROLLED",
        # "pp_CustomerID":"test",
        # "pp_CustomerEmail":"test@test.com",
        # "pp_CustomerMobile":"033456789025",
        # "result_CardEnrolled":"CARD_NOT_ENROLLED",
        # "c3DSecureID":"20190515095244486750",
        # "aR_Simple_Html":"",
        # "secureHash":"",
        # "pp_IsRegisteredCustomer":"Yes",
        # "responseCode":"433",
        # "responseMessage":"Card holder is not enrolled"        
        def initialize(post, options = {})
          super
          @raw = post
          @params = post
        end

        def errors
          @error ||= []
        end

        def summary_status
          @params['summaryStatus']
        end
        
        def customer_id
          @params['pp_CustomerID']
        end
        
        def customer_email
          @params['pp_CustomerEmail']
        end
        
        def customer_mobile
          @params['pp_CustomerMobile']
        end

        def result_card_enrolled
          @params['result_CardEnrolled']
        end

        def c3d_secure_id
          @params['c3DSecureID']
        end
        
        def ar_simple_html
          @params['aR_Simple_Html']
        end

        def secure_hash
          @params['pp_SecureHash']
        end

        def is_registered_customer
          @params['pp_IsRegisteredCustomer']
        end

        def response_code
          @params['pp_ResponseCode']
        end

        def response_message
          @params['pp_ResponseMessage']
        end

        def status
          response_code
        end
        
        def success?
          @params['pp_ResponseCode'] == '000'
        end
        
        def status_message
          response_message
        end

        def validate_secure_hash(salt)
          if secure_hash
            hash_items = [salt]
            if @params['pp_Version'] == '2.0'
              excluded_params = ['pp_SecureHash']
            else
              excluded_params = ['pp_SecureHash']#excluded for basic integration errors: , 'pp_ResponseCode', 'pp_ResponseMessage']
            end
            @params.keys.sort.each do |k| 
              if k =~ /\App/ && !excluded_params.include?(k) && @params[k].present?
                hash_items << @params[k]
              end
            end
            secure_hash == OpenSSL::HMAC.hexdigest('SHA256', salt, hash_items.join('&')).upcase
          else
            true
          end
        end

        def acknowledge(salt = nil)                   
          if success?
            if salt
              if validate_secure_hash(salt)
                true
              else
                errors << "Response is forged."
                true
              end
            else
              true
            end
          else
            if salt && !validate_secure_hash(salt)
              errors << "Response is forged."
            end
            errors << "#{@params['pp_ResponseCode']}: #{@params['pp_ResponseMessage']}"
            false
          end
        end
      end

      class Return < OffsitePayments::Return
      end
    end
  end
end
