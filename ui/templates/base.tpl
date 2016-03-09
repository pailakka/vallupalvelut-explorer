<!DOCTYPE html>
<html>
<head>
    {% block head %}
    <link rel="stylesheet" href="{{STATIC_URL}}css/bootstrap.min.css">
    <link rel="stylesheet" href="{{STATIC_URL}}css/bootstrap-theme.min.css">
    <link rel="stylesheet" href="{{STATIC_URL}}css/jquery-ui.min.css">
    <link rel="stylesheet" href="{{STATIC_URL}}css/typeahead.css">
    <script src="{{STATIC_URL}}js/jquery-1.11.1.min.js"></script>
    <script src="{{STATIC_URL}}js/bootstrap.min.js"></script>
    <script src="{{STATIC_URL}}js/jquery-ui.min.js"></script>
    <script src="{{STATIC_URL}}js/typeahead.bundle.min.js"></script>
    <title>VALLU-tietopalvelut - {% block title %}{% endblock %}</title>
    {% endblock %}
    <style type="text/css">{% block style %}{% endblock %}</style>
    <script type="text/javascript">function getCookie(name) {
    var r = document.cookie.match("\\b" + name + "=([^;]*)\\b");
    return r ? r[1] : undefined;
}
{% block script %}{% endblock %}</script>
</head>
<body>
    <div class="container-fluid">

      <!-- Static navbar -->
      <div class="navbar navbar-default" role="navigation">
        <div class="container-fluid">
          <div class="navbar-header">
            <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target=".navbar-collapse">
              <span class="sr-only">Toggle navigation</span>
              <span class="icon-bar"></span>
              <span class="icon-bar"></span>
              <span class="icon-bar"></span>
            </button>
            <a class="navbar-brand" href="/joukkoliikenne">Joukkoliikenne</a>
          </div>
          <div class="navbar-collapse collapse">
            <ul class="nav navbar-nav">
              <li><a href="/joukkoliikenne">Etusivu</a></li>
              {#<li><a href="{{ reverse_url('pysakit') }}">Pysäkkihaku</a></li>#}
              <li class="dropdown">
                <a href="#" class="dropdown-toggle" data-toggle="dropdown">Reitit<span class="caret"></span></a>
                <ul class="dropdown-menu" role="menu">
                  <li><a href="{{ reverse_url('reitit') }}">Haku</a></li>
                  <li><a href="{{ reverse_url('reitit.kautta') }}">Pysäkin kautta kulkevat</a></li>
                  <li><a href="{{ reverse_url('reitit.matriisi') }}">Kahden paikan välillä</a></li>
                </ul>
              </li>
              {#}
              <li><a href="#">Sopimushaku</a></li>
              <li><a href="#">Liikennöitsijähaku</a></li>
              #}
              <!--

              -->
            </ul>
          </div><!--/.nav-collapse -->
        </div><!--/.container-fluid -->
      </div>
      {% block content %}{% endblock %}
      </div>
</body>
</html>
