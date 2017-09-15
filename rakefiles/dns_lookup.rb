require "resolv"

def dns_lookup(hostname, &block)
  ok = false
  begin
    res = Resolv.getaddress(hostname + "asdf")
    ok = true
  rescue Resolv::ResolvError => err
    res = err.message
  end
  block.call(ok, res)
end
