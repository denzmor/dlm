#!/bin/bash

# This program is used to list, add or remove a vip on a server
# The program has to run by root

# 2016.02.05  Alain Grenier   Initial writing
# 2016.03.01  Alain Grenier   Added gratuitous ARP to inform of IP activation.
# 2016.03.08  J-B Trouve      Fixed interface identification for removal ($8 => $NF)

show_usage()
{
        echo -e "\nUsage: $0 {add <ip>|add <name>|remove <ip>|remove <name>|list|list ip_and_vip}"
        echo -e "\nWhen called with no arguments, it list the vip on this system\n"
}

me=$(whoami)

if [[ $me != "root" ]] ; then
        echo -e "\tYou need to be root to run this script"
        exit 1
fi

identify_interface()
{
        # The VIP has to be passed as argument, it has to be an address, not a name
        # this function print the interface_name and the mnetmask bit size on stdout on success

        # Parameter : IP_address
        # Ouput on STDOUT: enX bits (or empty string if interface not found)
        export IP_ADDR=$1
        ip addr show primary | perl -e '
        use strict;
        my $ip_addr=$ENV{"IP_ADDR"};
        while(<>)
        {
                chomp;
                my @words = split();
                if( scalar (@words) == 7 && $words[0] eq "inet" && $words[2] eq "brd" && $words[4] eq "scope" && $words[5] eq "global" )
                {
                        my ($ip,$bits,$bcast,$interface) = ( split("/",$words[1]), $words[3], $words[6]);
                        my $mask = mask_from_bits($bits);
                        # print STDERR "raw: [$ip $bits $mask $bcast $interface]\n";
                        # print STDERR "cooked: [".fmt_ip($ip)."][".mask_ip($ip,$mask)."][".fmt_ip($bcast)."]\n";
                        if( fmt_ip($ip_addr) ge mask_ip($ip,$mask) && fmt_ip($ip_addr) le fmt_ip($bcast) )
                        {
                                # The IP falls between the subnet base address and broadcast (max): use this enX
                                print "$interface $bits\n";
                                exit;
                        }
                }
        }
        print "\n";

        sub mask_from_bits()
        {
                my($bits) = @_;
                my $mask_number = (2**32-1)-(2**(32-$bits)-1);
                return sprintf("%d.%d.%d.%d",
                        int ( $mask_number / ( 2**24 ) ) % 256,
                        int ( $mask_number / ( 2**16 ) ) % 256,
                        int ( $mask_number / ( 2**8 ) ) % 256,
                        $mask_number % 256 );
        }
        sub mask_ip()
        {
                my($my_ip,$my_mask) = @_;
                my @i=split(/\./,$my_ip);
                my @m=split(/\./,$my_mask);
                my $n0 = int($i[0]) & int($m[0]);
                my $n1 = int($i[1]) & int($m[1]);
                my $n2 = int($i[2]) & int($m[2]);
                my $n3 = int($i[3]) & int($m[3]);
                return sprintf("%03d.%03d.%03d.%03d", $n0 , $n1, $n2, $n3 );
        }

        sub fmt_mask()
        {
                my($mask) = @_;
                my @o=split(/\./,$mask);
                # printf("MASK: $mask = %03d.%03d.%03d.%03d\n",$o[0],$o[1],$o[2],$o[3]);
                return sprintf("%03d.%03d.%03d.%03d",$o[0],$o[1],$o[2],$o[3]);
        }

        sub fmt_ip()
        {
                my($ip) = @_;
                my @o=split(/\./,$ip);
                # printf("IP: $ip = %03d.%03d.%03d.%03d\n",$o[0],$o[1],$o[2],$o[3]);
                return sprintf("%03d.%03d.%03d.%03d",$o[0],$o[1],$o[2],$o[3]);
        }
        '  # End of Perl section
}

chk_ping()
{
        # this function will return 0 (true) if the VIP respond to ping
        # this function will return 1 (false) if the VIPs does not respond to ping (it is ok to configure it)
        # The VIP has to be passed as argument, it can be an address or a dns name
        ret=1
        ping_ip=$1
        if ping -c 1 -W 1 $ping_ip > /dev/null 2>&1
                then
                echo -e "\t$ping_ip is reponding to ping"
                ret=0
        else
                echo -e "\t$ping_ip is not reponding to ping"
        fi
        return $ret
}

_address=""
get_address()
{
        # This function return the address of a name or abort
        # The address is set in the global variable _address when the return value is 0 (true)
        vip=$1
        pattern="[0-9]+\.[0-9]+\.[0-9]+\.[0-9]"
        ret=1
        OLD_IFS=$IFS
        IFS=" "
        if [[ $vip =~ $pattern ]]  ; then
                _address=$vip
                ret=0
        else
                host_resolution=$(host $vip)
                if [[ $host_resolution =~ 'has address' ]] ; then
                        read -ra words <<< $host_resolution
                        _address=${words[3]}
                        if [[ -z "$_address" ]] ; then
                                echo -e "\tProblem to read the IP"
                        else
                                ret=0
                        fi
                else
                        echo -e "\tCannot find address of vip $vip"
                fi
        fi
        IFS=$OLD_IFS
        return $ret
}

add_vip()
{
        # This function configure the vip passed as argument, it can be ian address or dns name
        # Obtain an adress if it is a dns name
        vip=$1
        if ! get_address $vip ; then
                echo -e "\tCannot resolve the $vip addres; aborting"
                exit 1
        elif chk_ping $_address ; then
                echo -e "\tThe vip ($vip) already respond to ping; we will not try to configure it"
        else
                read interface bits <<<  $(identify_interface $_address)
                if [[ -n "$bits" ]] ; then
                        echo -e "\tConfiguring vip ($vip) on interface ($interface) using ip ($_address/$bits)"
                        ip addr add $_address/$bits dev $interface

                        # Send ARP response to tell telecom equipment IP has moved.
                        arping -c 4 -A -I  $interface $_address
                else
                        echo -e "\tCannot find an interface to configure this vip ($vip); Aborting"
                        exit 1
                fi
        fi
}

del_vip()
{
        # This function remove a configured vip passed as argument, it can be ian address or dns name
        # Obtain an adress if it is a dns name
        vip=$1
        if ! get_address $vip ; then
                echo -e "\tCannot resolve the $vip addres; aborting"
                exit 1
        else
                found=0
                for ip in `ip addr show secondary | awk -F '[ /]+' '$2=="inet" {print $3}'`
                do
                        if [[ "$ip" == "$_address" ]] ; then
                                read interface bits <<< $( ip addr show secondary | awk -v ip=$ip -F '[ /]+' '$2=="inet" && $3==ip {print $NF,$4}')
                                if [[  -n "$interface" ]] ; then
                                        echo -e "\tUnconfiguring vip ($vip) on interface ($interface) with ip ($_address/$bits)"
                                        ip addr del $_address/$bits dev $interface
                                        found=1
                                else
                                        echo -e "\tCannot find the interface of this vip ($vip), ip ($_address); Aborting"
                                        exit 1
                                fi
                        fi
                done
                if [[ $found == 0 ]] ; then
                        echo -e "\tThe provided vis ($vip) with ip ($_address) is not configured on that server; Aborting"
                        exit 1
                fi
        fi
}

list()
{
        sec="secondary"
        if [[ "$1" == "ip_and_vip" ]] ; then
                sec=""
        fi

        for i in `ip addr show $sec | awk -F '[ /]+' '$2=="inet" {print $3}'`
        do
                j=$(host $i | awk '{print $5}' | sed 's/\..*//')
                echo "$j $i" | awk '{printf "%-20s %s\n",$1,$2}'
        done
}

# MAIN section

if [[ -z "$1" ]] ; then
        list
else
case    "$1" in
        add)
                ip_name=$2
                add_vip $ip_name
                ;;

        remove)
                ip_name=$2
                del_vip $ip_name
                ;;

        list)
                list $2
                ;;

        *)
                show_usage
                ;;

esac
fi


