import tornado.web
from jinja2 import Environment, FileSystemLoader, TemplateNotFound
import logging
import os
import psycopg2.extras

app_log = logging.getLogger("tornado.application")

class TemplateRendering:
    """
    A simple class to hold methods for rendering templates.
    """
    def render_template(self, template_name, **kwargs):
        template_dirs = []
        if self.settings.get('template_path', ''):
            template_dirs.append(
                self.settings["template_path"]
            )
        template_name = '%s.tpl' % template_name
        env = Environment(loader=FileSystemLoader(template_dirs))

        try:
            template = env.get_template(template_name)
        except TemplateNotFound:
            raise TemplateNotFound(template_name)
        content = template.render(kwargs)
        return content

class BaseHandler(tornado.web.RequestHandler, TemplateRendering):
    @property
    def cursor(self,*args):

        cursor = self.application.dbconn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        return cursor

    def render2(self, template_name, **kwargs):
        kwargs.update({
            'settings': self.settings,
            'STATIC_URL': self.settings.get('static_url_prefix', '/static/'),
            'request': self.request,
            'xsrf_token': self.xsrf_token,
            'xsrf_form_html': self.xsrf_form_html,
            'reverse_url':self.reverse_url
        })
        content = self.render_template(template_name, **kwargs)
        self.write(content)
