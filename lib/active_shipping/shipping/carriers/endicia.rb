module ActiveMerchant
  module Shipping
    class Endicia < Carrier
      cattr_accessor :default_options
      cattr_reader :name
      @@name = "Endicia"
      @@uuid = UUID.new

      TEST_URL = 'https://www.envmgr.com/LabelService/EwsLabelService.asmx'

      RESOURCES = {
        :get_postage_label => ['GetPostageLabelXML', 'labelRequestXML'],
        :change_passphrase => ['ChangePassPhraseXML', 'changePassPhraseRequestXML'],
      }

      def self.uuid
        @@uuid.generate
      end

      def buy_shipping_labels(shipper, origin, destination, packages, options = {})
        shipment = Shipment.new(
          :shipper => shipper,
          :payer => (options[:payer] || shipper),
          :origin => origin,
          :destination => destination,
          :packages => packages,
          :number => options[:shipment_number],
          :service => (options[:service] || 'MediaMail')
        )
        packages.each do |package|
          request = build_label_request(shipment, package)
          response = commit(:get_postage_label, request, true)
          parse_label_response(package, response)
          shipment.labels << package.label
        end
        shipment
      end

      def change_passphrase(shipper, passphrase = nil)
        passphrase ||= ActiveSupport::SecureRandom.base64(64)
        request = build_change_passphrase_request(shipper, passphrase)
        response = commit(:change_passphrase, request, true)
        parse_change_passphrase_response(shipper, response)
        shipper.passphrase = passphrase
        shipper
      end

      private

      def requirements
        [:partner_id]
      end

      def build_label_request(shipment, package)
        xml = Builder::XmlMarkup.new
        xml.instruct!
        xml.LabelRequest('Test' => 'YES') do
          xml.RequesterID @options[:partner_id]
          xml.AccountID shipment.shipper.number
          xml.PassPhrase shipment.shipper.passphrase
          xml.MailClass shipment.service
          xml.WeightOz package.ounces
          xml.MailpieceShape 'Parcel'
          xml.Services 'InsuredMail' => 'OFF', 'SignatureConfirmation' => 'OFF'
          xml.PartnerCustomerID shipment.shipper.attention
          xml.PartnerTransactionID shipment.number
          add_location_element(xml, 'To', shipment.destination)
          add_location_element(xml, 'From', shipment.origin)
          xml.ResponseOptions 'PostagePrice' => 'TRUE'
        end
        xml.target!
      end

      def add_location_element(xml, name, object)
        if object.attention.blank?
          xml.tag!(name + 'Name', object.name)
        else
          xml.tag!(name + 'Name', object.attention)
          xml.tag!(name + 'Company', object.name)
        end
        values = [
          [object.address1, 'Address1'],
          [object.address2, 'Address2'],
          [object.address3, 'Address3'],
          [object.city, 'City'],
          [object.state, 'State'],
          [object.postal_code, 'PostalCode'],
          [object.phone, 'Phone']
        ]
        values.select {|v, n| !v.blank?}.each do |v, n|
          if name == 'From' && %w(Address1 Address2 Address3).include?(n)
            xml.tag!('Return' + n, v)
          else
            xml.tag!(name + n, v)
          end
        end
      end

      def parse_label_response(package, response)
        xml = REXML::Document.new(response)
        label_response = xml.elements['/LabelRequestResponse']
        if (code = label_response.text('Status')) != '0'
          package.errors << ResponseError.new(code, label_response.text('ErrorMessage'))
          return false
        end
        package.label = Base64.decode64(label_response.text('Base64LabelImage'))
        package.tracking = label_response.text('TrackingNumber')
        package.cost = Money.new(label_response.text('FinalPostage').to_f * 100)
        package
      end

      def build_change_passphrase_request(shipper, passphrase)
        xml = Builder::XmlMarkup.new
        xml.instruct!
        xml.ChangePassPhraseRequest do
          xml.RequesterID @options[:partner_id]
          xml.RequestID self.class.uuid
          xml.CertifiedIntermediary do
            xml.AccountID shipper.number
            xml.PassPhrase shipper.passphrase
          end
          xml.NewPassPhrase passphrase
        end
        xml.target!
      end

      def parse_change_passphrase_response(shipper, response)
        xml = REXML::Document.new(response)
        root = xml.elements['/ChangePassPhraseRequestResponse']
        if (code = root.text('Status')) != '0'
          raise ResponseError.new(code, root.text('ErrorMessage'))
        end
        shipper
      end
      def commit(action, request, test = false)
        resource = RESOURCES[action]
        ssl_post("#{test ? TEST_URL : LIVE_URL}/#{resource[0]}", resource[1] + '=' + request)
      end

      def buy_postage
      end

      def change_pass_phrase
      end

      def calculate_postage_rate
      end

      def get_account_status
      end

      def refund_request
      end

      def user_signup
      end

      def status_request
      end

      def get_transactions_listing
      end

      def scan_request
      end

      def carrier_pickup_request
      end

      def carrier_pickup_cancel
      end

      def carrier_pickup_change
      end

      def multi_location_carrier_pickup
      end

      class ResponseError < RuntimeError
        attr :code, :message

        def initialize(code, message)
          @code = code
          @message = message
        end
      end
    end
  end
end
