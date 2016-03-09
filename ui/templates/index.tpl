{% extends "base.tpl" %}
{% block title %}Etusivu{% endblock %}
{% block style %}
#pysakkiInput,
#vuoroInput,
#reittiInput,
#sopimusInput,
#liikennInput
 {
    width:500px;
}
{% endblock %}
{% block content %}
    <h1>Pikahaku</h1>
    {#}
    <h3>Pysäkkihaku</h3>
    <form class="form-inline" role="form" method="get" action="{{ reverse_url('pysakit') }}">
    <div class="form-group">
    <input type="text" class="form-control" id="pysakkiInput" name="q" placeholder="Pysäkin valtakunnallinen tunnus tai nimi"/>
    <input type="submit" class="btn btn-default" value="Hae"/>
    </div>
    </form>
    <h3>Vuorohaku</h3>
    <form class="form-inline" role="form" method="post" action="#">
    {{xsrf_form_html()}}
    <div class="form-group">
    <input type="text" class="form-control" id="vuoroInput" placeholder="Vuoron pysyvä tunnus"/>
        <input type="submit" class="btn btn-default" value="Hae"/>
    </div>
    </form>
    #}
    <h3>Reittihaku</h3>
    <form class="form-inline" role="form" method="post" action="{{ reverse_url('reitti') }}" id="reittisearch">
    {{xsrf_form_html()}}
    <div class="form-group">
    <input type="text" class="form-control" id="reittiInput" name="reittiid" placeholder="Reitin pysyvä tunnus"/>
        <input type="submit" class="btn btn-default" value="Hae"/>
    </div>
    </form>
    {#
    <h3>Sopimushaku</h3>
    <form class="form-inline" role="form" method="post" action="#">
    {{xsrf_form_html()}}
    <div class="form-group">
    <input type="text" class="form-control" id="sopimusInput" placeholder="Lupa/sopimustunnus"/>
        <input type="submit" class="btn btn-default" value="Hae"/>
    </div>
    </form>
    <h3>Liikennöitsijähaku</h3>
    <form class="form-inline" role="form" method="post" action="/joukkoliikenne/liikennoitsijat">
    {{xsrf_form_html()}}
    <div class="form-group">
    <input type="text" class="form-control" id="liikennInput" placeholder="Liikennöitsijän tunnus tai nimi"/>
        <input type="submit" class="btn btn-default" value="Hae"/>
    </div>
    </form>
    #}
{% endblock %}

<script>
{% block script %}
$(function () {
    $('#reittisearch').submit(function (e) {
        location.href = $('#reittisearch').attr('action') + $('#reittiInput').val();
        return false;
    })
});
{% endblock %}
</script>
