#encoding UTF-8
#!/usr/bin/env ruby
require 'socket'
require 'timeout'
require 'english'

Signal.trap('INT') do
  @client.close if @client
  exit
end

Service = Struct.new(:name, :port)

class CheckServers
  attr_accessor :io

  def initialize(io = STDOUT)
    @io = io
    @services = [Service.new('Rails',  3000),
                 Service.new('Jekyll', 4000),
                 Service.new('Joodo',  8080),]
  end

  def self.run
    server = TCPServer.new 2000
    self.new.accept_loop(server)
  end

  def puts(msg = '')
    @io.puts(msg)
  end

  def accept_loop(server)
    puts 'Server started on port 2000'
    puts '---------------------------'
    loop do
      @client = server.accept
      pid = fork do
        rows = []
        _, _, _, @remote_ip = @client.peeraddr
        puts "[Client Connected][#{@remote_ip}]"

        ip_addresses(`arp -a`).each do |ip|
          puts "[#{@remote_ip}][#{ip}]"
          add_services(ip)
        end

        @client.puts(html do
          rows.map { |r| "<td>#{r.join('</td><td>')}</td>" }.join('</tr><tr>')
        end)

        @client.close
        puts '[Client Closed]'
      end
      Process.detach(pid)
    end
  end

  def add_services(ip)
    servers = ["#{ip} #{hostname(`smbutil status #{ip}`)}"]
    @services.each do |s|
      servers << port_html(ip)
    end
    rows << servers
  end

  def port_html(service, ip)
    if port_open?(ip, service.port, 1)
      "<a href='http://#{ip}:#{service.port}' class='btn btn-success'>Online</a>"
    else
      '<a class="btn btn-danger disabled" href="#">Offline</a>'
    end
  end

  def ip_addresses(network_info)
    network_info
      .split(/\s/)
      .select { |ip| ip =~ /\(.*\)/   }
      .map    { |ip| ip.delete('()')  }
      .reject { |ip| ip == @remote_ip }
      .reject { |ip| ip.split('.').last.to_i > 254 }
      .reject { |ip| ip.split('.').last.to_i < 2   }
      .uniq
  end

  def hostname(name)
    name.split.last
  end

  def port_open?(ip, port, seconds = 0.3)
    timeout(seconds) do
      begin
        TCPSocket.new(ip, port).close
        true
      rescue
        false
      end
    end
  end

  def html(&block)
    <<-HTML
    <html>
      <head>
        <title></title>
        <link rel="shortcut icon" href="#" />
        <link rel="stylesheet" href="http://twitter.github.io/bootstrap/assets/css/bootstrap.css" />
      </head>
      <body style="margin:10px;">
        <header>
          <h1>All currently connected computers on the network</h1>
          <h3>Time is #{Time.now}</h3><br/>
          <hr>
        </header>
        <section>
          <table class="table table-striped table-hover table-bordered">
            <tr>
              <th>Address</th><th>Rails<small>(3000)</small></th><th>Jekyll</th><th>Jodoo</th>
            </tr>
            <tr>
              #{yield}
            </tr>
          </table>
        </section>
      </body>
    </html>
    HTML
  end

end
