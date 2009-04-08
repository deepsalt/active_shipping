module ActiveMerchant
  module Shipping
    class Endicia < Carrier
      cattr_accessor :default_options
      cattr_reader :name
      @@name = "Endicia"
      @@uuid = UUID.new

      TEST_URL = 'https://www.envmgr.com/LabelService/EwsLabelService.asmx'

      LIVE_URL = 'https://www.envmgr.com/LabelService/EwsLabelService.asmx'

      RESOURCES = {
        :get_postage_label => ['GetPostageLabelXML', 'labelRequestXML'],
        :change_passphrase => ['ChangePassPhraseXML', 'changePassPhraseRequestXML'],
        :buy_postage => ['BuyPostageXML', 'recreditRequestXML'],
        :postage_rate => ['CalculatePostageRateXML', 'postageRateRequestXML'],
      }

      SERVICES = {
        'Express' => 'Express Mail',
        'First' => 'First-Class Mail',
        'LibraryMail' => 'Library Mail',
        'MediaMail' => 'Media Mail',
        'ParcelPost' => 'Parcel Post',
        'ParcelSelect' => 'Parcel Select',
        'Priority' => 'Priority Mail'
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
          :service => options[:service]
        )
        packages.each do |package|
          request = build_label_request(shipment, package)
          response = commit(:get_postage_label, request)
          parse_label_response(package, response)
          shipment.labels << package.label
        end
        shipment
      end

      def change_passphrase(shipper, passphrase = nil)
        passphrase ||= ActiveSupport::SecureRandom.base64(64)
        request = build_change_passphrase_request(shipper, passphrase)
        response = commit(:change_passphrase, request)
        parse_change_passphrase_response(shipper, response)
        shipper.passphrase = passphrase
        shipper
      end

      def buy_postage(shipper, amount)
        request = build_recredit_request(shipper, amount)
        response = commit(:buy_postage, request)
        parse_recredit_response(shipper, response)
        shipper
      end

      def find_rates(shipper, shipment, services = nil)
        if services
          services = Array(services)
          if services.length != (services = services.to_set).length
            raise 'Duplicate services requested', ArgumentError
          end
          unless (services - SERVICES.keys).empty?
            raise 'Unknown services requested', ArgumentError
          end
        else
          services ||= SERVICES.keys
        end
        rates = {}
        services.each do |service|
          cost = shipment.packages.inject(Money.new(0)) do |total, package|
            request = build_postage_rate_request(shipper, shipment, package, service)
            response = commit(:postage_rate, request)
            parse_postage_rate_response(package, response)
            total += package.cost
          end
          rates[service] = cost
        end
        rates
      end

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
          add_package(xml, package)
          xml.Services 'InsuredMail' => 'OFF', 'SignatureConfirmation' => 'OFF'
          xml.PartnerCustomerID shipment.shipper.attention
          xml.PartnerTransactionID shipment.number
          add_location(xml, 'To', shipment.destination)
          add_location(xml, 'From', shipment.origin)
          xml.ResponseOptions 'PostagePrice' => 'TRUE'
        end
        xml.target!
      end

      def add_package(xml, package)
        xml.WeightOz package.ounces
        xml.MailpieceShape 'Parcel'
      end

      def add_location(xml, name, object)
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
        root = parse_response(response, 'LabelRequestResponse')
        package.label = Base64.decode64(root.text('Base64LabelImage'))
        package.tracking = root.text('TrackingNumber')
        package.cost = Money.new(root.text('FinalPostage').to_f * 100)
        package
      end

      def build_change_passphrase_request(shipper, passphrase)
        build_request('ChangePassPhraseRequest', shipper) do |xml|
          xml.NewPassPhrase passphrase
        end
      end

      def parse_change_passphrase_response(shipper, response)
        parse_response(response, 'ChangePassPhraseRequestResponse')
        shipper
      end

      def build_recredit_request(shipper, amount)
        build_request('RecreditRequest', shipper) do |xml|
          xml.RecreditAmount amount.to_s
        end
      end

      def parse_recredit_response(shipper, response)
        parse_response(response, 'RecreditRequestResponse')
        shipper
      end

      def build_postage_rate_request(shipper, shipment, package, service)
        build_request('PostageRateRequest', shipper) do |xml|
          xml.MailClass service
          add_package(xml, package)
          xml.FromPostalCode shipment.origin.postal_code
          xml.ToPostalCode shipment.destination.postal_code
        end
      end

      def parse_postage_rate_response(package, response)
        root = parse_response(response, 'PostageRateResponse')
        package.cost = Money.new(root.text('Postage/Rate').to_f * 100)
        package
      end

      def build_request(name, shipper)
        xml = Builder::XmlMarkup.new
        xml.instruct!
        xml.tag!(name) do
          xml.RequesterID @options[:partner_id]
          xml.RequestID self.class.uuid
          xml.CertifiedIntermediary do
            xml.AccountID shipper.number
            xml.PassPhrase shipper.passphrase
          end
          yield xml
        end
        xml.target!
      end

      def parse_response(response, root_name)
        xml = REXML::Document.new(response)
        root = xml.elements['/' + root_name]
        if (code = root.text('Status')) != '0'
          raise ResponseError.new(code, root.text('ErrorMessage'))
        end
        root
      end

      def commit(action, request)
        resource = RESOURCES[action]
        base_url = test_mode? ? TEST_URL : LIVE_URL
        ssl_post("#{base_url}/#{resource[0]}", resource[1] + '=' + request)
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
