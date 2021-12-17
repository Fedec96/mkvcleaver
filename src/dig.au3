#include-once
#Include <String.au3>
#Include <Date.au3>

; You may add more "<rrtype>=<value>" pairs to $sDig_rr_types, if you want,
; but keep in mind, that you also need to add a portion of parsing code
; in DecodeRData(), if you want the ressource record data to be decoded.
; If your rrtype cannot be parsed, it will be returned undecoded in a
; generic format according to RFC 3597.
Global Const $sDig_rr_types="A=1 NS=2 CNAME=5 SOA=6 WKS=11 PTR=12 MX=15 TXT=16 AAAA=28 SRV=33 A6=38 ANY=255"

; You may add more "<rrclass>=<value>" pairs to $sDig_rr_classes, if you want...
Global Const $sDig_rr_classes="IN=1 ANY=255"


Global $bDig_amsg       ; holds the complete dns answer message
Global $iDig_ptr        ; Pointer needed for reading the answer message
Global $iDig_q_count    ; QDCOUNT (No. of messages in the question section)
Global $iDig_a_count    ; ANCOUNT (No. of messages in the answer section)
Global $iDig_au_count   ; AUCOUNT (No. of messages in the authority section)
Global $iDig_ar_count   ; ARCOUNT (No. of messages in the aditional section)
Global $sDig_output     ; the dig output will be saved here...

; #FUNCTION# ====================================================================================================================
; Name...........: _Dig
; Description ...: Queries a DNS server and returns the result in a 'dig' like format (not exactly, but near)
;                  to be parsed by yourself :-)
; Syntax.........: _Dig($sDig_domain[, $sDig_server = ""[, $iDig_port = 53[, $sDig_type = "A"[, $sDig_class = "IN" _
;                     [, $sDig_proto = "UDP"[, $sDig_timeout = 1]]]]]])
; Parameters ....: $sDig_domain  - Domain to query
;                  $sDig_server  - [optional] DNS server to query (default: primary DNS server set for the NIC @IPAddress1)
;                  $iDig_port    - [optional] port to be used for the query (default: 53)
;                  $sDig_type    - [optional] ressource record type to be queried (default: "A")
;                  $sDig_class   - [optional] ressource record class to be queried (default: "IN")
;                  $sDig_proto   - [optional] IP protocol to be used (default: "UDP")
;                  $sDig_timeout - [optional] Timeout in seconds to wait for a response (default: 1)
; Return values .: Success - a string formatted similar to a 'dig' query
;                  Failure - "", sets @error:
;                  |1 - something went wrong (sorry, no specific error messages at the moment)
; Author ........: Andreas Börner (mail@andreas-boerner.de)
; Modified.......: Andreas Börner (mail@andreas-boerner.de)
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......; No
; ===============================================================================================================================
Func _Dig($sDig_domain,$sDig_server=Default,$iDig_port=Default,$sDig_type=Default,$sDig_class=Default,$sDig_proto=Default,$sDig_timeout=Default)

    ; Check & replace 'Default' values for optional parameters
    if $sDig_server=Default Then $sDig_server=""
    if $iDig_port=Default Then $iDig_port=53
    if $sDig_type=Default Then $sDig_type="A"
    if $sDig_class=Default Then $sDig_class="IN"
    if $sDig_proto=Default Then $sDig_proto="UDP"
    if $sDig_timeout=Default Then $sDig_timeout=1

    ; the dig output will be saved here...
    $sDig_output=""

    ; if no DNS server is provided, get the primary DNS server for the @IPAddress1 network adapter
    if $sDig_server="" then $sDig_server=GetPrimaryDNS()

    $sDig_proto=StringUpper($sDig_proto)

    ; random hex number (2 bytes) serving as a handle for the data that will be received
    Local $dig_id = Hex(Random(0, 65535, 1), 4)

    ; set query flags (16 bit):
    ;   ........ ........
    ;   0                   QR (Query/Response Flag) (0: query / 1: for response)
    ;    0000               Opcode (Operation Code) (0: standard query)
    ;        0              AA (Authoritative Answer Flag) (always 0 in a query)
    ;         0             TC (Truncation Flag) (always 0 in a query)
    ;          1            RD (Recursion Desired) (we want recursive answers, if possible)
    ;
    ;            0          RA (Recursion Available) (always 0 in a query)
    ;             000       Z (Zero) (Three reserved bits set to zero)
    ;                0000   RCode (Response Code) (always 0 in a query)
    ;
    Local $dig_flags="0100"

    ; in a regular query there is one question (=> QDCOUNT=1) and no answers (ANCOUNT=AUCOUNT=ARCOUNT=0)
    Local $dig_counters="0001000000000000"

    ; Encode the domain to standard DNS name notation
    Local $sDig_domain_binary=EncodeName($sDig_domain)

    ; Encode the ressource record type and class to their binary equivalents
    Local $sDig_type_binary = EncodeType($sDig_type)
    Local $sDig_class_binary = EncodeClass($sDig_class)

    ; this is the complete query: <id/handle> <query-flags> <ressource-record-counters> <rr-type> <rr-class>
    Local $dig_request = $dig_id & $dig_flags & $dig_counters & $sDig_domain_binary & $sDig_type_binary & $sDig_class_binary ; this is our query

    ; In TCP mode, an additional length information (PDU length) has to be preceeded (the length of the whole request in bytes)
    ; To simplify matters, this length is calculated from the string length of $dig_request, divided by two.
    ; (Please note, that $dig_pdulen remains empty, if UDP protocol is used)
    Local $dig_pdulen=""
    if $sDig_proto="TCP" Then $dig_pdulen=Hex(StringLen($dig_request)/2,4)

    ; Now the request string can be completed finally
    $dig_request="0x" & $dig_pdulen & $dig_request

    ; start TCP or UDP service & open a socket
    ; (Shutdown TCP/UDP service, if no socket could be opened and return an error to the caller)
    Local $dig_sock
    if $sDig_proto="TCP" Then
        TCPStartup()
        $dig_sock = TCPConnect($sDig_server, $iDig_port)
        If @error Then
            TCPShutdown()
            SetError(1)
            Return ""
        EndIf
    Else
        UDPStartup()
        $dig_sock = UDPOpen($sDig_server, $iDig_port)
        If @error Then
            UDPShutdown()
            SetError(1)
            Return ""
        EndIf
    EndIf

    ; measure the query time for "Query time:" output
    ; (ok, it's more like 'just for fun...' :-)
    Local $query_time=TimerInit()

    ; send query to the TCP or UDP socket
    if $sDig_proto="TCP" Then
        TCPSend($dig_sock, $dig_request)
    Else
        UDPSend($dig_sock, $dig_request)
    EndIf

    ; waiting for the response...
    Local $tik = 0
    Do
        ; receive the response from the TCP or UDP socket
        if $sDig_proto="TCP" Then
            $bDig_amsg = TCPRecv($dig_sock, 512,1)
        Else
            $bDig_amsg = UDPRecv($dig_sock, 512,1)
        EndIf
        Sleep(100)
    Until $bDig_amsg <> "" Or TimerDiff($query_time)>$sDig_timeout*1000

    $query_time=Round(TimerDiff($query_time))

    ; Stop TCP/UDP service (not needed anymore)
    if $sDig_proto="TCP" Then
        TCPShutdown()
        ; While a dns response via UDP immediately starts with the Message ID, a TCP response
        ; is preceeded by a 2 byte PDU length (as well as the request; see above) and the
        ; message id follows at position 3 in the response data. As we don't need the PDU
        ; length for anything, we cut it from the responseand throw it away
        $bDig_amsg=BinaryMid($bDig_amsg,3)
    Else
        UDPShutdown()
    EndIf

    ; from here, there is no more difference in handling TCP or UDP responses

    ; check response & message ID...
    If $bDig_amsg = "" or StringMid(BinaryMid($bDig_amsg, 1, 2), 3) <> $dig_id Then
        ; received nothing - or something, but not our DNS response
        SetError(1)
        Return ""
    EndIf

    ; ############ Output the formatted response ###############
    ;###########################################################

    ; initialize the global message pointer
    $iDig_ptr=1

    ; output some 'dig' like headers
    $sDig_output&="; <<>> DiG for AutoIt 1.0.0 (" & $sDig_proto & ") <<>> " & $sDig_domain & " @" & $sDig_server & "#" & $iDig_port & " " & $sDig_type & @LF
    $sDig_output&=";; Got answer:" & @LF

    ; read ID's, flags & counters from message header
    $dig_id=ReadHex2Int(2)
    $dig_flags=ReadHex2Int(2)
    $iDig_q_count=ReadHex2Int(2)
    $iDig_a_count=ReadHex2Int(2)
    $iDig_au_count=ReadHex2Int(2)
    $iDig_ar_count=ReadHex2Int(2)

    ; extract some boolean flags from $dig_flags (see query generation above for more info)
    Local $dig_flags_flags=""
    if BitAND($dig_flags,32768) then $dig_flags_flags&=" qr" ; QR
    if BitAND($dig_flags,1024) then  $dig_flags_flags&=" aa" ; AA
    if BitAND($dig_flags,512) then   $dig_flags_flags&=" tr" ; TR
    if BitAND($dig_flags,256) then   $dig_flags_flags&=" rd" ; RD
    if BitAND($dig_flags,128) then   $dig_flags_flags&=" ra" ; RA

    ; extract opcode & rcode...
    ; mask 15th to 12th bit for opcode and shift result to get the integer opcode
    Local $dig_flags_opcode=BitShift(BitAND($dig_flags,30720),11)
    ; mask 4th to 1st bit for response code (no additional shift necessary)
    Local $dig_flags_rcode=BitAND($dig_flags,15)

    ; output flags, ID's & counters
    $sDig_output&=";; ->>HEADER<<- opcode: " & $dig_flags_opcode & ", status: " & $dig_flags_rcode & ", id: " & $dig_id & @LF
    $sDig_output&=";; flags:" & $dig_flags_flags & "; QUERY: " & $iDig_q_count & ", ANSWER: " & $iDig_a_count & ", AUTHORITY: " & $iDig_au_count & ", ADDITIONAL: " & $iDig_ar_count & @LF

    ; output ressource record sections
    if $iDig_q_count>0 Then
        $sDig_output&=@LF & ";; QUESTION SECTION:" & @LF & ";"
        ReadResourceRecords("q")
        ; forward an error from ReadRessourceRecords to the caller
        if @error Then
            SetError(1)
            return ""
        EndIf
    EndIf
    if $iDig_a_count>0 Then
        $sDig_output&=@LF & ";; ANSWER SECTION:" & @LF
        ReadResourceRecords("a")
        ; forward an error from ReadRessourceRecords to the caller
        if @error Then
            SetError(1)
            return ""
        EndIf
    EndIf
    if $iDig_au_count>0 Then
        $sDig_output&=@LF & ";; AUTHORITY SECTION:" & @LF
        ReadResourceRecords("au")
        ; forward an error from ReadRessourceRecords to the caller
        if @error Then
            SetError(1)
            return ""
        EndIf
    EndIf
    if $iDig_ar_count>0 Then
        $sDig_output&=@LF & ";; ADDITIONAL SECTION:" & @LF
        ReadResourceRecords("ar")
        ; forward an error from ReadRessourceRecords to the caller
        if @error Then
            SetError(1)
            return ""
        EndIf
    EndIf

    $sDig_output&=@LF & ";; Query time: " & $query_time & " msec" & @LF

    ; Sorry - there is no reliable way to determine the origin of the received dns response
    ; using the AutoIt TCP / UDP functions, as TCPRecv() / UDPRecv() does not reveal the
    ; TCP / UDP headers to the end user and we have nothing to output on the SERVER line
    ; ";; SERVER: 192.168.4.254#53(192.168.4.254)"

    ; ok, the last two are easy...
    $sDig_output&=";; WHEN: " & _Now() & @LF
    $sDig_output&=";; MSG SIZE  rcvd: " & BinaryLen($bDig_amsg) & @LF

    ; Done...
    Return $sDig_output
EndFunc   ;==>_Dig

; read a ressource record section from the response message
Func ReadResourceRecords($section_id)
    Local $i,$count
    Local $name_dec,$type_dec,$class_dec,$ttl_dec,$rd_len,$data_dec,$iDig_ptr_end

    Switch $section_id
        case "q"
            $count=$iDig_q_count
        case "a"
            $count=$iDig_a_count
        case "au"
            $count=$iDig_au_count
        case "ar"
            $count=$iDig_ar_count
        case Else
            SetError(1)
            return ""
    EndSwitch

    for $i=1 to $count
        ; every ressource record contains a name, a type and a class
        $name_dec=DecodeName()
        $type_dec=DecodeType()
        $class_dec=DecodeClass()

        ; only ANSWER, AUTHORITY & ADDITIONAL records contain a ttl and record data
        $ttl_dec=""
        $data_dec=""
        if $section_id<>"q" Then
            $ttl_dec=ReadHex2Int(4)
            $rd_len=ReadHex2Int(2)
			$iDig_ptr_end=$iDig_ptr+$rd_len
            $data_dec=DecodeRData($rd_len,$type_dec)
        EndIf

        $sDig_output&=$name_dec & @TAB & $ttl_dec & @TAB & $class_dec & @TAB & $type_dec & @TAB & $data_dec & @LF
    Next
EndFunc

; encode a literal domain name to standard DNS name notation
Func EncodeName($sDig_domain)
    Local $ret="",$i,$sDig_domain_array

    ; split domain name into separate labels (a label means everything in front of a dot)
    $sDig_domain_array = StringSplit($sDig_domain, ".")

    ; append every label with it's preceeded length value to the return value
    For $i = 1 To $sDig_domain_array[0]
        ; append label length (1 byte) and label (as binary) to the encoded name
        $ret&=Hex(BinaryLen($sDig_domain_array[$i]), 2) & StringTrimLeft(StringToBinary($sDig_domain_array[$i]), 2)
    Next
    ; add a zero length value to finish the encoded name
    $ret&="00"

    return $ret
EndFunc

; decode standard DNS name notation to a literal domain name
; this is only the starter for a (possibly) recursive DecodeNameRec() run
Func DecodeName()
    Local $ret
    $ret=DecodeNameRec($iDig_ptr)

    ; It doesn't look "right" to simply add a period, if  $ret is empty
    ; but I taxed my brain and didn't find the solution to handle the case
    ; of a zero length label INSIDE the label decoding function and not as a
    ; special case. If somebody knows the solution (there MUST be some
    ; stupidly simple solution...), please let me know. :-)
    ; If you want to hurt your brain, simply dig for a non-existent host
    ; or IP - you should get a zero length label in the authority section.
    if $ret="" then $ret="."

    $iDig_ptr+=@extended
    return $ret
EndFunc

; recursive decode DNS name notation
; DecodeNameRec() calls itself recursively if it stumbles upon a pointer to another
; label in the response message
Func DecodeNameRec($offset)
    local $data,$data_dec="",$offset_ptr,$len

    Local $offset_add=0

    while 1
        $len=ReadHex2Int(1,$offset+$offset_add,False)
        ; a label is followed by a pointer or the name consists of a pointer only (0b11xxxxxx) => need to decode recursive
        if BitAND(192,$len)=192 then
            ; get the pointer offset (filter the upper two bits (pointer identifier) from the value)
            $offset_ptr=BitAND(ReadHex2Int(2,$offset+$offset_add,False),16383)+1
            ; DecodeNameRec() is called recursive targetting the offset in the
            ; response message, until a label is found that DOES NOT end with a pointer
            ; the decoding is complete, if all recursions returned
            $data_dec&=DecodeNameRec($offset_ptr)
            ; offset the read position behind the pointer
            $offset_add+=2
            ExitLoop
        ; a label is followed by a label length (i.e. no pointer)
        Else
            ; offset the read position behind the label length value
            $offset_add+=1
            ; label length zero => the name is completly decoded => return to caller
            if $len=0 then ExitLoop
            $data=BinaryMid($bDig_amsg,$offset+$offset_add,$len)
            $data_dec&=_HexToString(StringMid($data,3)) & "."
            ; offset the read position behind the label
            $offset_add+=$len
        EndIf
    WEnd
    ; return the new offset (to DecodeName() if this is the 1st recursion level)
    ; (Hint: a new offset from the 2nd recursion level and below, i.e. if DecodeNameRec() returns to itself,
    ; is ignored, because it must not change the global read position.)
    SetExtended($offset_add)
    Return $data_dec
EndFunc

; encode ressource record type from string to 16 bit hex value
Func EncodeType($rr_type)
    Local $ret

    ; search the integer value according to $rr_type in $sDig_rr_types
    $ret=StringRegExp(" " & $sDig_rr_types & " "," " & StringUpper($rr_type) & "=([0-9]+) ",1)

    ; if found: return this integer value hex encoded (16 bit)
    if not @error then
        Return Hex($ret[0],4)
    ; if not found...
    Else
        ; ...test, if $rr_type was given as a generic rrtype according to RFC 3597 ("TYPExxx")
        ; and return xxx value hex encoded (16 bit)
        if StringLeft(StringUpper($rr_type),4)="TYPE" Then
            Return Hex(StringMid($rr_type,5),4)
        ; ...else, set @error=1 and return RR type "ANY" (255)
        Else
            SetError(1)
            return "00FF"
        EndIf
    EndIf
EndFunc

; decode ressource record type from 16 bit hex value to string
Func DecodeType($advance=True)
    Local $ret=""

    Local $rr_type=ReadHex2Int(2,$iDig_ptr,$advance)

    ; search the name according to $rr_type value in $sDig_rr_types
    $ret=StringRegExp(" " & $sDig_rr_types & " "," ([0-9,A-Z]+)=" & $rr_type & " ",1)

    ; if found:
    if not @error then
        Return $ret[0]
    ; if not found return unknown rrtype as "TYPExxx" according to RFC 3597
    Else
        return "TYPE" & $rr_type
    EndIf
EndFunc

; encode ressource record class from string to 16 bit hex value
Func EncodeClass($rr_class)
    Local $ret

    ; search the integer value according to $rr_class in $sDig_rr_classes
    $ret=StringRegExp(" " & $sDig_rr_classes & " "," " & StringUpper($rr_class) & "=([0-9]+) ",1)

    ; if found: return this integer value hex encoded (16 bit)
    if not @error then
        Return Hex($ret[0],4)
    ; if not found...
    Else
        ; ...test, if $rr_class was given as a generic rrclass according to RFC 3597 ("CLASSxxx")
        ; and return xxx value hex encoded (16 bit)
        if StringLeft(StringUpper($rr_class),5)="CLASS" Then
            Return Hex(StringMid($rr_class,6),4)
        ; ...else, set @error=1 and return RR class "ANY" (255)
        Else
            SetError(1)
            return "00FF"
        EndIf
    EndIf
EndFunc

; decode ressource record class from 16 bit hex value to string
Func DecodeClass($advance=True)
    Local $ret=""

    Local $rr_class=ReadHex2Int(2,$iDig_ptr,$advance)

    ; search the name according to $rr_class value in $sDig_rr_classes
    $ret=StringRegExp(" " & $sDig_rr_classes & " "," ([0-9,A-Z]+)=" & $rr_class & " ",1)

    ; if found:
    if not @error then
        Return $ret[0]
    ; if not found return unknown rrclass as "CLASSxxx" according to RFC 3597
    Else
        return "CLASS" & $rr_class
    EndIf
EndFunc

; decode ressource record data types
; Currently DecodeRData() decodes only the most important ressource record types
; record types, that are unknown, are returned in a generic (undecoded) format defined
; in RFC 3597 (see below)
Func DecodeRData($len,$type_dec,$advance=True)
    local $ret="",$i,$data,$string_len

    ; decode known rr types
    Switch $type_dec

        ; IPv4 internet address record
        case "A"
            $ret&=ReadHex2Int(1)            ; IP - 1st octet (no preceding dot)
            for $i=2 to 4                   ; IP - 2nd to 4th octet
                $ret&="." & ReadHex2Int(1)
            Next

        ; IPv6 internet address record
        case "AAAA"
            ; convert binary to hex value & insert colons
            for $i=1 to 8
                ; short IPv6 notation Pt. 1: strip up to 3 leading zeros from every group (but leave one zero untouched)
                $data=StringRegExpReplace(Hex(BinaryMid($bDig_amsg,$iDig_ptr,2)),"^0{1,3}","")
                $ret&=$data & ":"
                $iDig_ptr+=2
            Next
            ; short IPv6 notation Pt. 2: replace the first occurrence
            ; of one or more consecutive groups of :0 with a colon
            ; (and trim the last colon)
            ; (Hint: this approach does not necessarily return the shortest possible notation,
            ; as it always compresses the FIRST occurrence of at least one ":0",
            ; even if there is a longer group somewhere else in the address.)
            $ret=StringTrimRight(StringRegExpReplace($ret,"(:0)+",":",1),1)

        ; mail exchange record
        case "MX"
            $ret&=ReadHex2Int(2)            ; mx preference
            $ret&=" " & DecodeName()        ; mx host name

        ; canonial name record
        ; name server record
        ; pointer record
        case "CNAME","NS","PTR"
            $ret=DecodeName()               ; host name / ns name

        ; start of authority record
        case "SOA"
            $ret&=DecodeName()              ; Primary Nameserver
            $ret&=" " & DecodeName()        ; Admin Mailbox (first dot is equivalent to '@')
            $ret&=" " & ReadHex2Int(4)      ; Serial Number
            $ret&=" " & ReadHex2Int(4)      ; Refresh interval
            $ret&=" " & ReadHex2Int(4)      ; Retry Interval
            $ret&=" " & ReadHex2Int(4)      ; Expiration Limit
            $ret&=" " & ReadHex2Int(4)      ; Minimum TTL

        ; service locator record
        case "SRV"
            $ret&=ReadHex2Int(2)            ; Priority
            $ret&=" " & ReadHex2Int(2)      ; Weight
            $ret&=" " & ReadHex2Int(2)      ; Port
            $ret&=" " & DecodeName()        ; host name

        ; text record
        ; sender policy framework record
        case "SPF","TXT"
            ; Althrough the RDLENGTH field already contains a 2-byte length for the TXT/SPF record (as for any other ressource record type)
            ; the record itself consists of zero or more strings, preceeded by a single byte length value. These strings have to be
            ; read one after another.
            $ret=''
            $data=BinaryMid($bDig_amsg,$iDig_ptr,$len)
            while BinaryLen($data)>0
                $string_len=int("0x"&Hex(BinaryMid($data,1,1)))
                $ret&='"' & BinaryToString(BinaryMid($data,2,$string_len)) & '" '
                $data=BinaryMid($data,$string_len+2)    ; cut $data after $string_len bytes (plus 1 for the length byte itself)
            WEnd
            $ret=StringTrimRight($ret,1)
            $iDig_ptr+=$len

        ; all unknown ressource record data are returned in a generic (undecoded) hex format
        case Else
            $ret="\# " & $len & " " & hex(BinaryMid($bDig_amsg,$iDig_ptr,$len)) ; return rdata of unknown record types according to RFC 3597
            $iDig_ptr+=$len
    EndSwitch
    Return $ret
EndFunc

; read $len bytes from the response message
; if not explicitly given, read starts from the current global read position
; if not explicitly False, global read position is set behind the read data
Func ReadHex2Int($len,$offset=$iDig_ptr,$advance=True)
    Local $ret

    $ret=Int("0x"&hex(BinaryMid($bDig_amsg,$offset,$len)))
    if $advance then $iDig_ptr+=$len
    return $ret
EndFunc


; get primary dns server from the network adapter with @IPAddress1 from NetworkAdapterConfiguration WMI object
Func GetPrimaryDNS()
    Local $ret

    ; some constants & variables needed for the WMI object
    Const $wbemFlagReturnImmediately = 0x10
    Const $wbemFlagForwardOnly = 0x20
    Local $colNICs="", $NIC, $strQuery, $objWMIService

    ; query the network adapter configuration to $colNICs
    $strQuery = "SELECT * FROM Win32_NetworkAdapterConfiguration"
    $objWMIService = ObjGet("winmgmts:\\.\root\CIMV2")
    $colNICs = $objWMIService.ExecQuery($strQuery, "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)

    ; search @IPAddress1 in result object / if found, set return value to the first DNSServerSearchOrder element
    If IsObj($colNICs) Then
        For $NIC In $colNICs
            if $NIC.IPAddress(0)==@IPAddress1 then
                $ret=$NIC.DNSServerSearchOrder(0)
                ExitLoop
            EndIf
        Next
    Else
        SetError(-1, "No WMI Objects Found for class: Win32_NetworkAdapterConfiguration", "")
    EndIf

    ; free the WMI object
    $objWMIService = ""
    $colNICs = ""
    $NIC = ""

    Return $ret
EndFunc