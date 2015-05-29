#!/opt/rbenv/versions/2.2.2/bin/ruby
# prints mostly used methods
# @ton31337 <donatas.abraitis@gmail.com>

require 'optparse'

options = {:count => 20,
           :refresh => 1,
           :sort => 0,
           :class => nil,
           :gt => 0,
           :path => "/opt/rbenv/versions/2.2.2/bin/ruby"}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: rubytop.rb [options]"

  opts.on('-g', '--greater <integer>', 'Filter if latency is greater than X ms') do |gt|
    options[:gt] = gt.to_i * 1000;
  end

  opts.on('-n', '--num <integer>', 'Show only X entries') do |count|
    options[:count] = count;
  end

  opts.on('-p', '--path <string>', 'Ruby path') do |path|
    options[:path] = path;
  end

  opts.on('-r', '--refresh <integer>', 'Refresh interval') do |refresh|
    options[:refresh] = refresh;
  end

  opts.on('-s', '--sort_time', 'Sort by time') do |sort|
    options[:sort] = 1;
  end

  opts.on('-c', '--class <string>', 'Filter only by class') do |klass|
    options[:class] = klass;
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end

end

parser.parse!

content = <<EOF
global calls;
global etimes;
global sort_etime=#{options[:sort]};

@define skip(x,y) %( if(isinstr(@x, @y)) next; %)
@define only(x,y) %( if(!isinstr(@x, @y)) next; %)
@define stats %( printf("<%d.%06d> tid:%-8d count:%-8d [%s#%s] %s:%d\\n",
  (etime / 1000000), (etime % 1000000),
  tid, calls[tid, class, method, file, line, etime], class, method, file, line) %)

function print_head()
{
        ansi_clear_screen();
        printf("Probing...Type CTRL+C to stop probing.\\n");
}

function print_stats()
{
        if(sort_etime) {
              foreach([tid, class, method, file, line, etime-] in calls limit #{options[:count]})
                      @stats;
        } else {
              foreach([tid, class, method, file, line, etime] in calls- limit #{options[:count]})
                      @stats;
        }
}

probe process("#{options[:path]}").mark("method__entry")
{
        class = user_string($arg1);
        method = user_string($arg2);
        @skip(class, "Kernel");
EOF
if options[:class]
content += <<EOF
        @only(class, \"#{options[:class]}\");
EOF
end
content += <<EOF
        etimes[tid(), class, method] = gettimeofday_us();
}

probe process("#{options[:path]}").mark("method__return")
{
        class = user_string($arg1);
        method = user_string($arg2);
        file = user_string($arg3);
        line = $arg4;
        @skip(class, "Kernel");
EOF
if options[:class]
content += <<EOF
        @only(class, \"#{options[:class]}\");
EOF
end
content += <<EOF
        etime = gettimeofday_us() - etimes[tid(), class, method];
        if (!etimes[tid(), class, method] || etime < #{options[:gt]})
                next;

        calls[tid(), class, method, file, line, etime]++;
}

probe timer.s(#{options[:refresh]}) {
        print_head();
        print_stats();
        delete calls;
        delete etimes;
}

probe end {
        delete calls;
        delete etimes;
}
EOF

print "Compiling, please wait...\n"
IO.popen("echo '#{content}' | stap -DMAXMAPENTRIES=102400 -g --suppress-time-limits -") do |cmd|
  print $_ while cmd.gets
end
