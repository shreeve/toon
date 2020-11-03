require 'zones'

class Object
  def blank?
    respond_to?(:empty?) or return !self
    empty? or respond_to?(:strip) && strip.empty?
  end unless defined? blank?
end

$STATE_MAP ||= <<~end.split(/(?:\n|  +)/).inject({}) {|h, e| h.store(*e.split(' ', 2)); h}
  AK Alaska                LA Louisiana       PA Pennsylvania
  AL Alabama               MA Massachusetts   PR Puerto Rico
  AR Arkansas              MD Maryland        RI Rhode Island
  AS American Samoa        ME Maine           SC South Carolina
  AZ Arizona               MI Michigan        SD South Dakota
  CA California            MN Minnesota       TN Tennessee
  CO Colorado              MO Missouri        TX Texas
  CT Connecticut           MS Mississippi     UT Utah
  DC District of Columbia  MT Montana         VA Virginia
  DE Delaware              NC North Carolina  VI Virgin Islands
  FL Florida               ND North Dakota    VT Vermont
  GA Georgia               NE Nebraska        WA Washington
  GU Guam                  NH New Hampshire   WI Wisconsin
  HI Hawaii                NJ New Jersey      WV West Virginia
  IA Iowa                  NM New Mexico      WY Wyoming
  ID Idaho                 NV Nevada
  IL Illinois              NY New York
  IN Indiana               OH Ohio
  KS Kansas                OK Oklahoma
  KY Kentucky              OR Oregon
end

$STATE_ABBREV ||= $STATE_MAP.inject({}) {|h, (k, v)| h[k] = h[v.upcase] = k; h }

def toon(str, func=nil, *args, **opts, &code)
  if block_given?
    yield str
  else
    return if str.nil? #!# TOO CRAZY?
    case func
    when nil then str
    when 'age' #!# FIXME: what about timezone shifts, etc?
      dob = Date.new(*Time.parse_str(str)[0])
      ref = args[0].respond_to?(:to_time) ? args[0].to_date : Date.today
      yrs = ref.year - dob.year
      yrs -= 1 if (ref.month < dob.month) || ((ref.month == dob.month) && (ref.day < dob.day))
      yrs

    when 'date_on' then str.to_tz.to_date                  rescue nil # date object
    when 'time_at' then str.to_tz.getutc                   rescue nil # time object
    when 'isodate' then str.to_tz.       strftime("%F"   ) rescue ""  # date string
    when 'isotime' then str.to_tz.getutc.strftime("%F %T") rescue ""  # time string

    when 'date'
      str.to_tz.strftime("%m/%d/%Y") rescue ""
    when 'Time'
      str.to_tz
    when 'timestamp'
      str.to_tz.strftime("%m/%d/%Y %H:%M:%S") rescue ""
    when 'hispanic'
      str =~ /hispanic|latin/i ? "Y" : "N"
    when 'sex'
      str =~ /\A(m|male|f|female|o|other)\z/i ? $1[0].upcase : '' # M/F/O
    when 'state'
      $STATE_ABBREV[str.upcase] || ''
    when 'to_decimal'
      prec = 2
      if str[/\A\s*\$?\s*([-+])?\s*\$?\s*([-+])?\s*(\d[,\d]*)?(\.\d*)?\s*\z/]
        sign = "#{$1}#{$2}".squeeze.include?("-") ? "-" : ""
        left = $3.blank? ? "0" : $3.delete(",")
        decs = $4.blank? ? nil : $4
        "%.*f" % [prec, "#{sign}#{left}#{decs}".to_f]
      else
        ""
      end
    when 'to_map'
      map = args[0]; map.is_a?(Hash) or raise "to_map unable to map using #{map.inspect}"
      map.key?(str) ? map[str] : begin
        case val = map[:else]
          when :pass  then str
          when Proc   then str.instance_eval(&val)
          when Symbol then str.send(val)
          else val
        end
      end
    when 'to_phone', 'phone'
      return "" if str.blank?
      num = str.to_s.squeeze(' ').strip
      num, ext = num.split(/\s*(?:ext?\.?|x|#|:|,)\s*/i, 2)
      ext.gsub!(/\D+/,'') if ext
      num = num.sub(/\A[^2-9]*/, '').gsub(/\D+/, '')
      if num =~ /\A([2-9][0-8][0-9])([2-9]\d\d)(\d{4})\z/
        num = "(#{$1}) #{$2}-#{$3}"
        num << ", ext. #{ext}" if num && ext
      else
        num = ext = nil
      end
      num
    when 'to_yyyymmdd_hmZ'
      str.to_tz.utc.to_s[0...-4]
    when 'to_yyyymmdd'
      case str
        when /^((?:19|20)\d{2})(\d{2})(\d{2})$/      then "%s%s%s"       % [$1, $2, $3          ] # YYYYMMDD
        when /^(\d{2})(\d{2})((?:19|20)\d{2})$/      then "%s%s%s"       % [$3, $1, $2          ] # MMDDYYYY
        when /^(\d{1,2})([-\/.])(\d{1,2})\2(\d{4})$/ then "%s%02d%02d"   % [$4, $1.to_i, $3.to_i] # M/D/Y
        when /^(\d{4})([-\/.])(\d{1,2})\2(\d{1,2})$/ then "%s%02d%02d"   % [$1, $3.to_i, $4.to_i] # Y/M/D
        when /^(\d{1,2})([-\/.])(\d{1,2})\2(\d{2})$/
          year = $4.to_i
          year += year < (Time.now.year % 100 + 5) ? 2000 : 1900
          "%04d%02d%02d" % [year, $1.to_i, $3.to_i] # M/D/Y
        else ""
      end
    when 'to_yyyymmdd_ymd'
      toon(str, 'to_yyyymmdd') =~ /^(\d{4})(\d{2})(\d{2})$/ ? "#{$2}/#{$3}/#{$1}" : str
    when 'to_yyyymmdd_ymd_iso'
      str.to_tz.utc.to_s[0...-4]
    when 'tune'
      o = {}; opts.each {|e| o[e]=true}
      s = str
      s = s.downcase.gsub(/\s\s+/, ' ').strip.gsub(/(?<=^| |[\d[:punct:]])([[[:alpha:]]])/i) { $1.upcase } # general case
      s.gsub!(/\b([a-z])\. ?([bcdfghjklmnpqrstvwxyz])\.?(?=\W|$)/i) { "#$1#$2".upcase } # initials (should this be :name only?)
      s.gsub!(/\b([a-z](?:[a-z&&[^aeiouy]]{1,4}))\b/i) { $1.upcase } # uppercase apparent acronyms
      s.gsub!(/\b([djs]r|us|acct|[ai]nn?|all|apps|ed|erb|esq|grp|in[cj]|of[cf]|st|up)\.?(?=\W|$)/i) { $1.capitalize } # force camel-case
      s.gsub!(/(^|(?<=\d ))?\b(and|at|as|of|the|in|not|on|or|for|to|by|de l[ao]s?|del?|(el-)|el|las)($)?\b/i) { ($1 || $3 || $4) ? $2.downcase.capitalize : $2.downcase } # prepositions
      s.gsub!(/\b(mc|mac(?=d[ao][a-k,m-z][a-z]|[fgmpw])|[dol]')([a-z])/i) { $1.capitalize + $2.capitalize } # mixed case (Irish)
      s.gsub!(/\b(ahn|an[gh]|al|art[sz]?|ash|e[dnv]|echt|elms|emms|eng|epps|essl|i[mp]|mrs?|ms|ng|ock|o[hm]|ong|orr|orth|ost|ott|oz|sng|tsz|u[br]|ung)\b/i) { $1.capitalize } # if o[:name] # capitalize
      s.gsub!(/(?<=^| |[[:punct:]])(apt?s?|arch|ave?|bldg|blvd|cr?t|co?mn|drv?|elm|end|f[lt]|hts?|ln|old|pkw?y|plc?|prk|pt|r[dm]|spc|s[qt]r?|srt|street|[nesw])\.?(?=\W|$)/i) { $1.capitalize } # if o[:address] # road features
      s.gsub!(/(1st|2nd|3rd|[\d]th|de l[ao]s)\b/i) { $1.downcase } # ordinal numbers
      s.gsub!(/(?<=^|\d |\b[nesw] |\b[ns][ew] )(d?el|las?|los)\b/i) { $1.capitalize } # uppercase (Spanish)
      s.gsub!(/\b(ca|dba|fbo|ihop|mri|ucla|usa|vru|[ns][ew]|i{1,3}v?)\b/i) { $1.upcase } # force uppercase
      s.gsub!(/\b([-@.\w]+\.(?:com|net|io|org))\b/i) { $1.downcase } # domain names, email (a little bastardized...)
      s.gsub!(/# /, '#') # collapse spaces following a number sign
      s.sub!(/[.,#]+$/, '') # nuke any trailing period, comma, or hash signs
      s.sub!(/\bP\.? ?O\.? ?Box/i, 'PO Box') # PO Boxes
      s
    when 'zip', 'to_zip'
      str =~ /^(\d{5})-?\d{4}?$/ ? $1 : '' # only allow 5-digit zip codes
    when 'yn'
      # {"Y"=>"Y","N"=>"N"}[str.to_s[0].upcase] || ""
      str =~ /\A(y|yes|n|no)\z/i ? $1[0].upcase : '' # yes/no
    else
      if str.respond_to?(func)
        str.send(func, *args)
      else
        warn "dude... you gave me the unknown func #{func.inspect}"
        nil
      end
    end
  end
end

def toon!(rows, rules)
  todo = Hash[rules.scan(/^\s*(.*?)  +(.*?)(?:\s*#.*)?$/)]
  seen = 0
  diff = 0
  rows.each_with_index do |cols, r|
    seen += 1
    todo.update(Hash[cols.map.with_index {|name, c| [c, [name, todo[name]]]}]) if seen == 1
    cols.each_with_index do |cell, c|
      name, func = todo[c]
      orig = cell
      cell = toon(cell, func) if func && seen > 1
      if cell != orig
        diff += 1
        cols[c] = cell
      end
    end
  end
  # puts "#{diff} changes made" if diff > 0
  rows
end
