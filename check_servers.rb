#encoding UTF-8
#!/usr/bin/env ruby
require 'socket'
require 'timeout'
require 'english'


Signal.trap('INT') do
  @client.close if @client
  puts 'Goodbye'
  exit
end

def run
  links = []
  server = TCPServer.new 2000
  puts 'Server started on port 2000'
  puts '---------------------------'
  loop do
    @client = server.accept
    pid = fork do
      sock_domain, remote_port, remote_hostname, @remote_ip = @client.peeraddr

      puts
      puts "[Client Connected][#{@remote_ip}]"
      puts

      ip_addresses.each do |ip|
        servers = ["#{ip} #{hostname(ip)}"]
        [3000, 4000, 8080].each do |port|
          if port_open?(ip, port, 1)
            servers << "<a href='http://#{ip}:#{port}' class='btn btn-success'>Online</a>"
          else
            servers << '<a class="btn btn-danger disabled" href="#">Offline</a>'
          end
        end
        links << servers
      end

      @client.puts(<<-HTML
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
                          #{
                            links.map do |link|
                              "<td>#{link.join('</td><td>')}</td>"
                            end.join('<tr/><tr>')
                           }
                        </tr>
                      </table>
                    </section>
                  </body>
                </html>
              HTML
             )
      @client.close
      links = []
      puts "[Client Closed]"
    end
    Process.detach(pid)
  end
end

def ip_addresses
  network_info = `arp -a`
  ips = network_info.split(/\s/).select { |ip_str| ip_str =~ /\(.*\)/ }.map { |ip| ip.delete('()') }
  puts ips.inspect
  ips.reject! { |ip| ip == @remote_ip }
  puts ips.inspect
  ips.reject! { |ip| ip.split('.').last.to_i > 254 }
  puts ips.inspect
  ips.reject! { |ip| ip.split('.').last.to_i < 2   }
  puts ips.inspect
  ips.uniq!
  return ips
  #(2..254).map { |x| "10.0.1.#{x}" }
end

def hostname(ip)
  `smbutil status #{ip}`.split.last
end

def port_open?(ip, port, seconds = 0.3)
  timeout(seconds) do
    begin
      puts "[#{@remote_ip}][#{ip}]"
      TCPSocket.new(ip, port).close
      return true
    rescue
      return false
    end
  end
rescue
  puts "[#{@remote_ip}][#{ip}][#{$ERROR_INFO}]"
  return false
end

run
