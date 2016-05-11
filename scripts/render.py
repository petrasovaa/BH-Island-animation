# -*- coding: utf-8 -*-
"""
Created on Tue May 10 20:52:25 2016

@author: anna
"""

import os
import wx
import wx.html2 as webview
from multiprocessing import Pool
import grass.script as gscript


TEMPLATE_HEADER = \
"""
<!doctype html>
<html lang="en">

    <head>
        <meta charset="utf-8">

        <title>Animation</title>

        <meta name="description" content="Bald Head Island">
        <meta name="author" content="Anna Petrasova">

        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">

        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, minimal-ui">

        <link rel="stylesheet" href="css/reveal.css">
        <link rel="stylesheet" href="css/theme/solarized.css" id="theme">

        <!-- Code syntax highlighting -->
        <link rel="stylesheet" href="lib/css/zenburn.css">

        <!-- Printing and PDF exports -->
        <script>
            var link = document.createElement( 'link' );
            link.rel = 'stylesheet';
            link.type = 'text/css';
            link.href = window.location.search.match( /print-pdf/gi ) ? 'css/print/pdf.css' : 'css/print/paper.css';
            document.getElementsByTagName( 'head' )[0].appendChild( link );
        </script>

        <!--[if lt IE 9]>
        <script src="lib/js/html5shiv.js"></script>
        <![endif]-->
    </head>

    <body>

        <div class="reveal">

            <!-- Any section element inside of this container is displayed as a slide -->
            <div class="slides">
"""
TEMPLATE_FOOTER = \
"""
            </div>

        </div>

        <script src="lib/js/head.min.js"></script>
        <script src="js/reveal.js"></script>

        <script>

            // Full list of configuration options available at:
            // https://github.com/hakimel/reveal.js#configuration
            Reveal.initialize({{
                controls: false,
                progress: false,
                history: false,
                center: true,
                transition: 'none', // none/fade/slide/convex/concave/zoom
                backgroundTransition: 'none', // none/fade/slide/convex/concave/zoom
                autoSlide: {},
                loop: true,

                // Optional reveal.js plugins
                dependencies: [
                    {{ src: 'lib/js/classList.js', condition: function() {{ return !document.body.classList; }} }},
                    {{ src: 'plugin/markdown/marked.js', condition: function() {{ return !!document.querySelector( '[data-markdown]' ); }} }},
                    {{ src: 'plugin/markdown/markdown.js', condition: function() {{ return !!document.querySelector( '[data-markdown]' ); }} }},
                    {{ src: 'plugin/highlight/highlight.js', async: true, callback: function() {{ hljs.initHighlightingOnLoad(); }} }},
                    {{ src: 'plugin/zoom-js/zoom.js', async: true }},
                    {{ src: 'plugin/notes/notes.js', async: true }}
                ]
            }});

        </script>

    </body>
</html>
"""


class WebAnimation(wx.Frame):
    def __init__(self, parent, size, pos):
        wx.Frame.__init__(self, parent=parent, size=size, pos=pos)
        panel = wx.Panel(self)
        self.wv = webview.WebView.New(panel)
        sizer = wx.BoxSizer()
        sizer.Add(self.wv, proportion=1, flag=wx.EXPAND)
        panel.SetSizer(sizer)
        sizer.Fit(panel)

    def SetURL(self, URL):
        self.wv.LoadURL(URL)


def rlake(args):
    try:
        elevation, level, seed, output = args
        env = os.environ.copy()
        reg = gscript.parse_command('g.region', flags='pg', env=env)
        env['GRASS_RENDER_IMMEDIATE'] = 'cairo'
        env['GRASS_RENDER_WIDTH'] = reg['cols']
        env['GRASS_RENDER_HEIGHT'] = reg['rows']
        env['GRASS_RENDER_FILE_READ'] = 'TRUE'
        env['GRASS_RENDER_FILE'] = output + '.png'
        env['GRASS_OVERWRITE'] = '1'
        env['GRASS_VERBOSE'] = '-1'
        gscript.run_command('r.lake', coordinates=seed, water_level=level,
                            elevation=elevation, lake=output, env=env)
        gscript.run_command('d.rast', map=elevation, env=env)
        gscript.run_command('d.rast', map=output, env=env)
    except:
        return


def writeHTML(path, images):
    with open(path, 'w') as f:
        f.write(TEMPLATE_HEADER)
        current = os.getcwd()
        for image in images:
            f.write('<section data-background="{}" '
                    'data-background-size=100%></section>\n'.format((os.path.join(current, image) + '.png').replace(' ', '\ ')))
        f.write(TEMPLATE_FOOTER.format(300))


def main(elevation, min_level, max_level, step, seed, series, html_file):
    parameters = []
    lake_name = series + '_{}'
    i = min_level
    names = []
    while i <= max_level:
        params = (elevation, i, seed, lake_name.format(i))
        names.append(lake_name.format(i))
        parameters.append(params)
        i += step
    pool = Pool(7)
    p = pool.map_async(rlake, parameters, chunksize=1)
    try:
        p.get()
    except:
        return
    writeHTML(html_file, names)

if __name__ == '__main__':
    elevation = 'elev_lid792_1m'
    min_level = 120
    max_level = 130
    step = 1
    series = 'lakeseries'
    seed = [638757.5, 220172.5]
    html_file = '/media/anna/My Passport/BH_project/BH-Island-animation/presentation/test.html'
    main(elevation, min_level, max_level, step, seed, series, html_file)
    app = wx.App()
    frame = WebAnimation(None, size=(700, 750), pos=(100, 100))
    frame.SetURL('file://' + html_file)
    frame.Show()
    app.MainLoop()
