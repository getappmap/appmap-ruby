#!/usr/bin/env ruby
# coding: utf-8
# A simple tabulate method to columnize data in console.
#
# author::  Roy Zuo (aka roylez)
#

# global template variable
# * :rs: record seperator
# * :hs: heading seperator
# * :fs: field seperator
# * :cross: the cross point of record seperator and field seperator
# * :lframe: left frame
# * :rframe: right frame
# * :hlframe: heading left frame
# * :hrframe: heading right frame
# * :padding: number of padding characters for each field on each side
#
$table_template = { 
    "simple" => { 
        :rs => '', :fs => ' | ',  :cross => '+',
        :lframe => '', :rframe => '' ,
        :hlframe => "\e[1;2m", :hrframe => "\e[m" ,
        :padding => 0,
    },
    "legacy" => {
        :rs => '', :fs => '|', :cross => '+',
        :lframe => '|', :rframe => '|',
        :hlframe => "|", :hrframe => "|",
        :tframe => "-", :bframe => "-",
        :hs => "=", :padding => 1,
    },
    'plain' => {
        :rs => '', :fs => ' ', :cross => '+',
        :lframe => '', :rframe => '',
        :hlframe => "", :hrframe => "",
        :padding => 0, 
    },
    'sqlite' => {
        :rs => '', :fs => '  ', :cross => '  ',
        :lframe => '', :rframe => '',
        :hlframe => "", :hrframe => "",
        :padding => 0, :hs => '-'
    },
    'plain2' => {
        :rs => '', :fs => ':', :cross => '+',
        :lframe => '', :rframe => '',
        :hlframe => "", :hrframe => "",
        :hs => "-", :padding => 1,
    },
    'plain_alt' => {
        :rs => '', :fs => ' ', :cross => '+',
        :lframe => '', :rframe => '',
        :hlframe => "", :hrframe => "",
        :hs => "-", :padding => 1,
    },
    'fancy' => {
        :rs => '', :fs => '|', :cross => '+',
        :lframe => '', :rframe => '',
        :hlframe => "\e[1;7m", :hrframe => "\e[m",
        :padding => 1,
    },
}
            
# tabulate arrays, it accepts the following arguments
# * :label: table headings, an array
# * :data: table data. Each elements stands for one *or more* rows.
#   For example, [[1, 2] , [3, [4, 5]], [nil, 6]] will be processed as 4 lines
#       +1      2+
#       +3      4+
#       +3      5+
#       +       6+
# * :opts: optional arguments, default to :indent => 0, :style => 'fancy'
# return a String
def tabulate(labels, data, opts = { } )
    raise 'Label and data do not have equal columns!' unless labels.size == data.transpose.size

    opts = { :indent => 0, :style => 'fancy'}.merge opts
    indent = opts[:indent]
    style = opts[:style]
    raise "Invalid table style!"    unless  $table_template.keys.include? style

    style = $table_template[style]

    data = data.inject([]){|rs, r| rs += r.to_rows }
    data = data.unshift(labels).transpose
    padding = style[:padding] 
    data = data.collect {|c| 
        c.collect {|e|  ' ' * padding + e.to_s + ' ' * padding } 
    }
    widths = data.collect {|c| c.collect {|a| a.width}.max } 
    newdata = []
    data.each_with_index {|c,i|
        newdata << c.collect { |e| e + ' '*(widths[i] - e.width) }
    }
    data = newdata
    data = data.transpose
    data = [ style[:hlframe] + data[0].join(style[:fs]) + style[:hrframe] ] + \
        data[1..-1].collect {|l| style[:lframe] + l.join(style[:fs]) + style[:rframe] }
    lines = []

    #add top frame
    if !style[:tframe].to_s.empty?
        lines << style[:cross] + widths.collect{|n| style[:tframe] *n }.join(style[:cross]) + style[:cross]
    end

    #add title 
    lines << data[0]

    #add title ruler
    if !style[:hs].to_s.empty? and !style[:lframe].to_s.empty?
        lines << style[:cross] + widths.collect{|n| style[:hs] *n }.join(style[:cross]) + style[:cross]
    elsif !style[:hs].to_s.empty?
        lines << widths.collect{|n| style[:hs] *n }.join(style[:cross])
    end

    #add data
    data[1..-2].each{ |line|
        lines << line
        if !style[:rs].to_s.empty?
            lines << style[:cross] + widths.collect{|n| style[:rs] *n }.join(style[:cross]) + style[:cross]
        end
    }

    #add last record and bottom frame
    lines << data[-1]
    if !style[:bframe].to_s.empty?
        lines << style[:cross] + widths.collect{|n| style[:bframe] *n }.join(style[:cross]) + style[:cross]
    end

    #add indent
    lines.collect {|l| ' '*indent + l}.join("\n")
end

class Array
    def to_rows
        a = collect{|i| i.is_a?(Array) ? i : [ i ]}
        nr = a.collect{|i| i.size}.max
        rows = []
        0.upto( nr-1 ) {|j| rows << a.collect{|i| i[j] ? i[j] : ''} }
        rows 
    end
end

class String
    if RUBY_VERSION >= '1.9'
        # test if string contains east Asian character (RUBY_VERSION > 1.9)
        def contains_cjk?               # Oniguruma regex !!!
            (self =~ /\p{Han}|\p{Katakana}|\p{Hiragana}\p{Hangul}/)
        end
    end
    # actual string width
    def width
        if RUBY_VERSION >= '1.9'
            gsub(/(\e|\033|\33)\[[;0-9]*\D/,'').split(//).inject( 0 ) do |s, i|
                s += i.contains_cjk? ? 2 : 1
                s 
            end
        else
            gsub(/(\e|\033|\33)\[[;0-9]*\D/,'').size
        end
    end
end

if __FILE__ == $0
    source = [["\e[31maht\e[m",3],[4,"\e[33msomething\e[m"],['s',['abc','de']]]
    labels = ["a",'b']
    puts "Available themes: #{$table_template.keys.inspect}"
    $table_template.keys.each do |k|
        puts "#{k} :"
        puts tabulate(labels, source, :indent => 4, :style => k)
        puts 
    end
end
