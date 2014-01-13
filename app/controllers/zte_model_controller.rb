class ZteModelController < ApplicationController
  def index

  end

  def g_command
    #gd1
    olt_id = params[:preconfig][:olt_id].to_s.strip
    #0011
    port = params[:preconfig][:port].to_s.strip
    #3
    #line_id = params[:preconfig][:line_id].to_s.strip
    #3
    #srv_id = params[:preconfig][:srv_id].to_s.strip
    #1001
    pe_vlan = params[:preconfig][:pe_vlan].to_s.strip
    #1386
    ce_vlan = params[:preconfig][:ce_vlan].to_s.strip
    #command no:32
    cmd_no = params[:preconfig][:cmd_no].to_s.strip
    #ont id
    ont_no = params[:preconfig][:ont_no].to_s.strip

    if olt_id.size != 8 || port.size != 3
      render template: 'welcome/error'
    else
      @passwd, @ont_str, @onu_str, @pon_str = ont_make(port, olt_id, ont_no.to_i, cmd_no.to_i, pe_vlan, ce_vlan)
    end
  end


  private
  #ont_make(6, 'wlt00100', 3, 3,32)
  #service_port_make(1318, '0/6/6', 1161,32)

  def newpass(len, prefix='')
    chars = ("a".."z").to_a + ("0".."9").to_a
    newpass = prefix.dup
    1.upto(len) { newpass << chars[rand(chars.size-1)] }
    newpass
  end

  def ont_make(port, pass_prefix, ont_no, count, pvlan, cvlan)
    pass_set = Set[]
    ont_str = []
    onu_str = []
    pon_str = []
    while pass_set.size != count do
      (1..count).each { pass_set << newpass(2, pass_prefix) }
    end
    #if pass_set.size == count
    #  pass_set.each { |s| puts s }
    #end

    inter_str = 'interface gpon-olt_' + port[0] + '/' + port[1] + '/' + port[2]
    ont_str << inter_str

    if pass_set.size == count
      pass_set.each_with_index do |set, index|
        t = index + ont_no
        if t < 100
          tmp = t.to_s.ljust(3)
        else
          tmp = t
        end
        ont_str << "onu #{t} type ZTEG-F601 pw #{set}"
        onu_str << inter_str + ":#{t}"
        onu_str << 'tcont 2 name tcont2 profile UP-10M'
        onu_str << 'gemport 1 unicast tcont 2 dir both queue 1'
        onu_str << 'encrypt 1 enable'
        onu_str << 'switchport mode hybrid vport 1'
        onu_str << "service-port 1 vport 1 user-vlan #{cvlan} vlan #{cvlan} svlan #{pvlan}"

        pon_str << inter_str + ":#{t}"
        pon_str << "service ServiceName type internet gemport 1 cos 0 vlan #{pvlan}"
        pon_str << "vlan port eth_0/1 mode tag vlan #{pvlan}"

      end
    else
      ont_str << "<span style='color:red'>命令生成错误，请重新生成.</span>"
    end
    [pass_set, ont_str, onu_str, pon_str]
  end
end
