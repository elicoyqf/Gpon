class WelcomeController < ApplicationController
  def index
  end

  def g_command
    #gd1
    olt_id  = params[:preconfig][:olt_id].to_s.strip
    #0011
    port    = params[:preconfig][:port].to_s.strip
    #3
    line_id = params[:preconfig][:line_id].to_s.strip
    #3
    srv_id  = params[:preconfig][:srv_id].to_s.strip
    #1001
    pe_vlan = params[:preconfig][:pe_vlan].to_s.strip
    #1386
    ce_vlan = params[:preconfig][:ce_vlan].to_s.strip
    #command no:32
    cmd_no  = params[:preconfig][:cmd_no].to_s.strip
    #ont id
    ont_no  = params[:preconfig][:ont_no].to_s.strip

    if olt_id.size != 8 || port.size != 4
      render template: 'welcome/error'
    else
      @passwd, @ont_str = ont_make(port, olt_id, line_id, srv_id, ont_no.to_i, cmd_no.to_i)
      @sp_str           = service_port_make(pe_vlan, port[0]+'/'+port[1..2]+'/'+port[3], ce_vlan.to_i, ont_no.to_i, cmd_no.to_i)
    end
  end

  private
  #ont_make(6, 'wlt00100', 3, 3,32)
  #service_port_make(1318, '0/6/6', 1161,32)

  def newpass(len, prefix='')
    chars   = ("a".."z").to_a + ("0".."9").to_a
    newpass = prefix.dup
    1.upto(len) { newpass << chars[rand(chars.size-1)] }
    newpass
  end

  def ont_make(port, pass_prefix, lineid, srvid, ont_no, count)
    pass_set = Set[]
    ont_str  = []

    if port[1].to_i == 0
      ont_str << "interface gpon " + port[0] + '/' + port[2] + '/' + port[3]
    else
      ont_str << "interface gpon " + port[0] + '/' + port[1] + port[2] + '/' + port[3]
    end

    #(1..count).each { pass_set << newpass(2, pass_prefix) }

    (1..count).each do |tmp|
      pass_set << newpass(2, pass_prefix)
      until pass_set.size == tmp
        pass_set << newpass(2, pass_prefix)
      end
    end

    if pass_set.size == count
      pass_set.each { |s| puts s }
      pass_set.each_with_index do |set, index|
        t = index + ont_no
        if t < 100
          tmp = t.to_s.ljust(3)
        else
          tmp = t
        end
        ont_str << "ont add #{port[3]} #{tmp} password-auth #{set} always-on omci ont-lineprofile-id #{lineid} ont-srvprofile-id #{srvid}"
      end
      ont_str << "quit"
    else
      ont_str << "<span style='color:red'>命令生成错误，请重新生成.</span>"
    end
    [pass_set, ont_str]
  end

  def service_port_make(pvlan, portinfo, cvlan, ont_no, count)
    sp_str = []
    (0..count-1).each do |index|
      t   = index + ont_no
      tmp =''
      if t < 100
        tmp = t.to_s.ljust(3)
      else
        tmp = t
      end
      sp_str << "service-port vlan #{pvlan} port #{portinfo} ont #{tmp} eth 1 multi-service user-vlan untagged tag-transform add-double inner-vlan #{cvlan+index} inner-priority 0"
    end
    sp_str
  end
end
