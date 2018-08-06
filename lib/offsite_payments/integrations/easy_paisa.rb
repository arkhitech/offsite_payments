# require 'offsite_payments/integrations/easy_paisa/helper'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module EasyPaisa

      module_function

      class Helper < OffsitePayments::Helper
        def credential_based_url
          unless test?
            if self.checkout_token
              'https://easypay.easypaisa.com.pk/easypay/Confirm.jsf'
            else
              'https://easypay.easypaisa.com.pk/easypay/Index.jsf'
            end
          else
            if self.checkout_token
              'https://easypaystg.easypaisa.com.pk/easypay/Confirm.jsf'
            else
              'https://easypaystg.easypaisa.com.pk/easypay/Index.jsf'
            end
          end
        end

        attr_accessor :errors

        def initialize(order, account, options = {})
          super(order, account, options)
          if options[:checkout_token]
            add_field('auth_token', options[:checkout_token])

            #append secret to the postBackUrl to validate transaction response received
            client_hashed_req = self.class.encrypt("#{order}", options[:credential4])
            return_url = URI(options[:return_url])
            return_url.query = return_url.query ? "#{return_url.query}&secret=#{client_hashed_req}" : "secret=#{client_hashed_req}"            
            add_field('postBackURL', return_url.to_s )
          else
            expiry_date=(Time.now.tomorrow).strftime("%Y%m%d %H%M%S")
            request_params = {
              'storeId' => options[:account_name],
              'amount' => options[:amount].to_s,
              'postBackURL' => options[:return_url],
              'orderRefNum'=> "#{order}",
              'expiryDate' => "#{expiry_date}",
              'autoRedirect' => '0',
              'paymentMethod' => 'CC_PAYMENT_METHOD',
              'emailAddr' => options[:credential2],
              'mobileNum' => options[:credential3]
            }

            add_field('storeId', options[:account_name])
            add_field('amount', options[:amount])
            add_field('postBackURL', options[:return_url])
            add_field('orderRefNum', "#{order}")
            add_field('expiryDate', expiry_date)
            add_field('autoRedirect', 0)
            add_field('paymentMethod', 'CC_PAYMENT_METHOD')
            add_field('emailAddr', options[:credential2])
            add_field('mobileNum', options[:credential3])
            add_field('merchantHashedReq', signed_request(options[:credential4], request_params))
          end

        end


        def errors
          @error ||= []
        end

        require 'openssl'
        require 'base64'

        def self.encrypt(raw_data, key)
          cipher = OpenSSL::Cipher.new("AES-128-ECB")
          cipher.encrypt()

          #convert key to hex key and pack (requirement for java padding
          hex_key = key.bytes.map { |b| sprintf("%02X",b) }.join
          key = [hex_key].pack('H*')

          cipher.key = key
          crypt = cipher.update(raw_data) + cipher.final

          Base64.encode64(crypt).gsub("\n",'')
        end

        def signed_request(hashKey, request_params)
          sorted_keys = request_params.keys.sort
          sorted_pairs = []
          sorted_keys.each do |key|
            sorted_pairs << "#{key}=#{request_params[key]}"
          end

          self.class.encrypt(sorted_pairs.join('&'), hashKey)
        end


        # Replace with the real mapping


#        mapping :store_id, 'store_id'
#        mapping :amount, 'amount'
#        mapping :post_back_url, 'postBackURL'
#        mapping :order, 'orderRefNum'
#        mapping :expiry_date, 'expiryDate'
#        mapping :merchant_hashed_req, 'merchantHashedReq'
#        mapping :auto_redirect, 'autoRedirect'
#        mapping :payment_method, 'paymentMethod'
#        mapping :email_address, 'emailAddr'
#        mapping :phone_number, 'mobileNum'



#        mapping :auth_token, 'AuthToken'


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

        def errors
          @error ||= []
        end

        def identifier
          params[:identifier]
        end
        
        def order_ref_number
          params[:orderRefNumber]
        end
        def transaction_number  
          order_ref_number
        end
        
        #Status of the transaction 
        # “Success”, “Failure”
        def status
          params[:status]
        end
        
        def success
          params[:success]
        end
        
        def transaction_number
          params[:transactionNumber]
        end

        def authorization
          transaction_number
        end
        
        
        #Code ID for the status
        def desc
          params[:desc]
        end
        
        def success?
          success == 'true' || status == 'Success' || status == '0000'# && params[:desc]=="Transaction Successful."
        end
        
        #Request Parameters
        #FieldName Description Mandatory (M) Data Type
        #username This will be provided by Easypay using “Manage Partner
        #
        #Account” screen
        #
        #M String
        #
        #password Encrypted password generated by “Manage Partner
        #
        #Account” screen
        #
        #M String
        #orderId Merchant’s system generated Order Id M String
        #accountNum Merchant’s Account Number registered with Easypay M String        
        #
        #
        #Response Parameters
        #Field Name Description Data Type
        #
        #responseCode
        #
        #Easypay generated response code. Possible values are:
        #0000 - Success 0001 - System Error 0002 - Required field is
        #missing 0003 - Invalid Order ID
        #0004 - Merchant Account does not exist 0005 - Merchant
        #Account is not active 0006 - Store does not exist
        #0007 - Store is not active String
        #orderId Merchant’s system generated Order Id String
        #storeId Merchant Account # registered in Fundamo Integer
        #accountNum Merchant Account No registered with Easypay String
        #storeName Merchant Store Name String
        #paymentToken Token generated in case of OTC String
        #transactionId Easypay generated unique Transaction Id String
        #transactionStatus Transaction Status possible Values are: REVERSED, PAID, String
        #transactionAmount Total transaction Amount Double
        #transactionDateTime Transaction Datetime Datetime
        #paymentTokenExiryDateTime Token expiration date time in case of OTC Datetime
        #transactionPaidDateTime Transaction Paid Date Time Datetime
        #Msisdn Customer MSISDN String
        #paymentMode Mode of payment (OTC, MA, ATM) TransactionType
        #TODO work in progress. Getting timeout
        def verify
          @client ||= Savon.client(wsdl: 'https://easypay.easypaisa.com.pk/easypay-service/PartnerBusinessService/META-INF/wsdl/partner/transaction/PartnerBusinessService.wsdl')
          @verify_response ||= @client.call(:inquire_transaction, 
            message: {username: '', password: '',
            orderId: order_ref_number, accountNum: '6542'}
          )
          
          response.body[:inquireTransactionResponseType]
        end
        def acknowledge(authcode = nil)
          unless success?
            errors << "Transaction Unsuccessful. For more information, please contact your card issuing bank."
            false
          else
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
