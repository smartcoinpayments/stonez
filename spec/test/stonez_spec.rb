require 'spec_helper'

describe 'Create and Configure Stonez' do

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
    params = {merchant_id: '8E51DE32849943389B67EC5E8AD7C721', hostname: 'dev-pos.stone.com.br', root_path: '', port: '443',  use_ssl: true }

    Stonez.configure do |config|
      config.merchant_id = params[:merchant_id]
      config.hostname    = params[:hostname]
      config.root_path   = params[:root_path]
      config.port        = params[:port]
      config.use_ssl     = params[:use_ssl]
    end

    tx_param ={cardholder_name: 'Arthur C Granado', pan: '4242424242424242', expiration_date: '2021-10', cvv: '081', parcelas: 1,
               short_name: 'Smartcoin' ,transaction_id: Random.rand(1000000).to_s, transaction_ref: SecureRandom.hex(7),
               total_amount: 1000, capture: true, transaction_dtime: Time.now.strftime("%Y-%m-%dT%H:%M:%S")}

    transaction = Stonez::Authorisation.new(tx_param)

    transaction.submit

    expect(transaction.capturada?).to be_truthy
  end
end