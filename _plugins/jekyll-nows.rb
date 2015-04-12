module Jekyll
  module Nows
    class OldBiosTag < Liquid::Tag
      def initialize(tag_name, text, tokens)
        super
      end

      def render(context)
        nows = Nows.get_nows(context.registers[:site])
        nows.reverse!

        html = '<ul class="old-bios">'
        nows.each do |now|
          unless now == nows.first
            short_date = now.data['date'].to_s
            long_date = now.data['date'].strftime('%B %d, %Y')
            html << "<li><a href=\"/nows/#{short_date}\">On #{long_date}, I was…</a></li>"
          end
        end
        html << '</ul>'

        html
      end
    end

    class NowsIndexPage < Page
      def initialize(site, base, dir)
        @site = site
        @base = base
        @dir = dir

        @ext = 'html'
        @basename = 'index.'

        @nows = Nows.get_nows(@site)
        @present_now = @nows[@nows.length - 1]

        self.read_yaml(File.join(@base, '_layouts'), 'nows_index.html')
        self.data['date'] = @present_now.data['date']
        self.data['present_now_content'] = @present_now.content
      end
    end

    class NowPage < Page
      def initialize(site, base, dir, this_now, previous_now, next_now, present_now)
        @site = site
        @base = base
        @dir = dir

        @this_now = this_now
        @previous_now = previous_now
        @next_now = next_now

        @ext = 'html'
        @basename = 'index.'

        self.read_yaml(File.join(@base, '_layouts'), 'now.html') 
        self.data['date'] = this_now.data['date']
        self.data['this_now_content'] = this_now.content
        self.data['present_now_content'] = present_now.content
        self.data['present_now_date'] = present_now.data['date']

        if previous_now
          self.data['previous_now_link'] = true
          self.data['previous_now_date'] = previous_now.data['date']
        else
          self.data['previous_now_link'] = false
        end

        if next_now and next_now == present_now
          self.data['next_now_link'] = "index"
        elsif next_now
          self.data['next_now_link'] = true
          self.data['next_now_date'] = next_now.data['date']
        else
          self.data['next_now_link'] = false
        end
      end
    end

    class NowsIndexPageGenerator < Generator
      safe true

      def generate(site)
        site.pages << NowsIndexPage.new(site, site.source, File.join('/'))
      end
    end

    class NowPageGenerator < Generator
      safe true

      def generate(site)
        nows = Nows.get_nows(site)
        present_now = nows[nows.length - 1]

        nows.each_with_index do |n,i|
          this_now = n
          case i
          when 0
            # Earliest
            previous_now = nil
            next_now = nows[i + 1]
          when nows.length - 1
            # Most Recent
            return # Break before generating a page
          else
            # The Rest
            previous_now = nows[i - 1]
            next_now = nows[i + 1]
          end

          site.pages << NowPage.new(
                        site, site.source, File.join('nows',this_now.data['date'].to_s),
                        this_now,previous_now,next_now,present_now)
        end
      end
    end

    def self.get_nows(site)
      nows = []
      if site.collections.key? 'nows'
        site.collections['nows'].docs.each do |d|
          nows << d

          if nows.length > 0
            nows.sort! { |a,b| a.data['date'] <=> b.data['date'] }
          end
        end
      end

      return nows
    end

  end
end

Liquid::Template.register_tag('old_bios', Jekyll::Nows::OldBiosTag)