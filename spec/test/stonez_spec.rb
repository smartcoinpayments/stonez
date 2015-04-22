require 'spec_helper'

describe 'Create and Configure Stonez' do
  let(:merchant_account_params) { {merchant_id: '8E51DE32849943389B67EC5E8AD7C721', hostname: 'dev-pos.stone.com.br', root_path: '', port: '443',  use_ssl: true } }

  before(:each) do
    Stonez.configure do |config|
      config.merchant_id = merchant_account_params[:merchant_id]
      config.hostname    = merchant_account_params[:hostname]
      config.root_path   = merchant_account_params[:root_path]
      config.port        = merchant_account_params[:port]
      config.use_ssl     = merchant_account_params[:use_ssl]
    end
  end

  it 'should create and configure Stonez instance' do
    params = {merchant_id: 'abc', hostname: 'hostname', root_path: '', port: '80',  use_ssl: false}
    Stonez.configure do |config|
      config.merchant_id = params[:merchant_id]
      config.hostname    = params[:hostname]
      config.root_path   = params[:root_path]
      config.port        = params[:port]
      config.use_ssl     = params[:use_ssl]
    end

    expect(Stonez.configuration).to_not be_nil
    expect(Stonez.configuration.merchant_id).to eq(params[:merchant_id])
    expect(Stonez.configuration.hostname).to eq(params[:hostname])
    expect(Stonez.configuration.root_path).to eq(params[:root_path])
    expect(Stonez.configuration.port).to eq(params[:port])
    expect(Stonez.configuration.use_ssl).to eq(params[:use_ssl])
  end

  it 'should authorize and capture a transaction' do
    tx_param ={cardholder_name: 'Luke Skywalker', pan: '4066559900000000', expiration_date: '2021-10', cvv: '081', parcelas: 1,
               short_name: 'Smartcoin' ,transaction_id: Random.rand(1000000).to_s, transaction_ref: SecureRandom.hex(7),
               total_amount: 1000, capture: true, transaction_dtime: Time.now.strftime("%Y-%m-%dT%H:%M:%S")}

    transaction = Stonez::Authorisation.new(tx_param)

    transaction.submit

    expect(transaction.autorizada?).to be_truthy
    expect(transaction.capturada?).to be_truthy
  end

  it 'should just authorize a charge' do
    tx_param ={cardholder_name: 'Luke Skywalker', pan: '4066559900000000', expiration_date: '2021-10', cvv: '081', parcelas: 1,
               short_name: 'Smartcoin' ,transaction_id: Random.rand(1000000).to_s, transaction_ref: SecureRandom.hex(7),
               total_amount: 1000, capture: false, transaction_dtime: Time.now.strftime("%Y-%m-%dT%H:%M:%S")}

    transaction = Stonez::Authorisation.new(tx_param)

    transaction.submit

    expect(transaction.autorizada?).to be_truthy
    expect(transaction.capturada?).to be_falsey
  end

  context 'Capture' do
    let(:tx_param) { {cardholder_name: 'Luke Skywalker', pan: '4066559900000000', expiration_date: '2021-10', cvv: '081', parcelas: 1,
                         short_name: 'Smartcoin' ,transaction_id: Random.rand(1000000).to_s, transaction_ref: SecureRandom.hex(7),
                         total_amount: 1000, capture: false, transaction_dtime: Time.now.strftime("%Y-%m-%dT%H:%M:%S")} }
    let(:transaction) { Stonez::Authorisation.new(tx_param) }

    before(:each) do
      transaction.submit
    end

    it 'should capture totally a charge amount that has authorized' do
      expect(transaction.autorizada?).to be_truthy
      expect(transaction.capturada?).to be_falsey

      capture_params = {id_stone: transaction.id, total_amount: tx_param[:total_amount]}
      capture_transaction = Stonez::Completion.new(capture_params)
      capture_transaction.submit

      expect(capture_transaction.success?).to be_truthy
    end

    it 'should capture partially a charge amount that has authorized' do
      expect(transaction.autorizada?).to be_truthy
      expect(transaction.capturada?).to be_falsey

      capture_params = {id_stone: transaction.id, total_amount: tx_param[:total_amount]/2 }
      capture_transaction = Stonez::Completion.new(capture_params)
      capture_transaction.submit

      expect(capture_transaction.success?).to be_truthy
    end
  end

  context 'Refund' do
    let(:transaction_id) {SecureRandom.hex(7)}
    let(:tx_param) { {cardholder_name: 'Luke Skywalker', pan: '4066559900000000', expiration_date: '2021-10', cvv: '081', parcelas: 1,
                         short_name: 'Smartcoin' ,transaction_id: transaction_id, transaction_ref: "Ref-#{Random.rand(1000000)}",
                         total_amount: 1000, capture: true, transaction_dtime: Time.now.strftime("%Y-%m-%dT%H:%M:%S")} }
    let(:transaction) { Stonez::Authorisation.new(tx_param) }

    before(:each) do
      transaction.submit
    end

    it 'should refund totally the charge amount' do
      expect(transaction.autorizada?).to be_truthy
      expect(transaction.capturada?).to be_truthy

      refund_params = {id_stone: transaction.id, transaction_id: transaction_id, total_amount: tx_param[:total_amount], transaction_dtime: Time.now.strftime("%Y-%m-%dT%H:%M:%S") }
      refund_transaction = Stonez::Cancellation.new(refund_params)
      refund_transaction.submit

      expect(refund_transaction.success?).to be_truthy
    end

    it 'should refund partially the charge amount' do
      expect(transaction.autorizada?).to be_truthy
      expect(transaction.capturada?).to be_truthy

      refund_params = {id_stone: transaction.id, transaction_id: transaction_id, total_amount: tx_param[:total_amount]/2, transaction_dtime: Time.now.strftime("%Y-%m-%dT%H:%M:%S") }
      refund_transaction = Stonez::Cancellation.new(refund_params)
      refund_transaction.submit

      expect(refund_transaction.success?).to be_truthy
    end
  end
end