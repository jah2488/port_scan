require_relative '../lib/check_servers'

describe CheckServers do
  subject { CheckServers.new(IO) }

  describe 'run' do
    it 'should start a tcp server on port 2000' do
      TCPServer.should_receive(:new).with(2000)
      CheckServers.any_instance.should_receive(:accept_loop)
      CheckServers.run
    end
  end

  describe 'port_open?' do

    before(:each) {
      TCPSocket.stub(:new) { socket }
      socket.should_receive(:close)
    }

    let(:socket) { double(:tcpsocket) }

    it 'true if the port is open' do
      subject.port_open?(0,3).should be_true
    end
  end

  describe 'innest' do
    it 'returns the online html link for true' do
      subject.stub(:port_open?).and_return(true)
      subject.innest(double(:port => 2), 10).should == "<a href='http://10:2' class='btn btn-success'>Online</a>"
    end

    it 'returns the offline html link for false' do
      subject.innest(double(:port => 2), 10).should == '<a class="btn btn-danger disabled" href="#">Offline</a>'
    end
  end

  describe 'ip_addresses' do
    let(:info) {
      '? (10.0.1.1) at ff:ff:ff:ff:ff:ff on en0 ifscope [ethernet]\n'   +
      '? (10.0.1.254) at ff:ff:ff:ff:ff:ff on en0 ifscope [ethernet]\n' +
      '? (10.0.1.255) at ff:ff:ff:ff:ff:ff on en0 ifscope [ethernet]'
    }

    it 'returns the formatted ip_addresses and removes the 1 and 255 intro' do
      subject.ip_addresses(info).should == ['10.0.1.254']
    end
  end

  describe 'hostname' do
    it 'grabs the last word in the output' do
      subject.hostname('10.0.1.10 \n status:\n server: POWERPC').should == 'POWERPC'
    end
  end
end

