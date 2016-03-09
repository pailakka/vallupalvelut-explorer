{% extends "base.tpl" %}
{% block title %}Reitit{% endblock %}
{% block content %}
    <div class="col-md-4">
    <h1>Reittihaku</h1>
    <form role="form" method="post" action="{{ reverse_url('reitit') }}" id="searchform">
    <div class="form-group">
        <label for="companyInput">Liikenteenharjoittaja</label>
        <input type="text" class="form-control" id="companyInput" name="company" placeholder="Liikenteenharjoittajan nimi tai tunnus"/>
    </div>
    <div class="form-group">
        <label for="sopimusInput">Sopimus</label>
        <input type="text" class="form-control" id="sopimusInput" name="sopimus" placeholder="Sopimustunnus"/>
    </div>
    <div class="form-group">
        <label for="reittiInput">Reitti</label>
        <input type="text" class="form-control" id="reittiInput" name="reitti" placeholder="Reitin nimi tai tunnus"/>
    </div>
    <div class="form-group">
        <label for="vuoroInput">Vuoro</label>
        <input type="text" class="form-control" id="vuoroInput" name="vuoro" placeholder="Vuoron tunnus"/>
    </div>
    <div class="form-group">
        <label>Haun tyyppi: </label>
        <input type="radio" name="type" value="and" id="typeand" checked="checked"><label for="typeand">kaikki ehdot</label>
        <input type="radio" name="type" value="or" id="typeor"><label for="typeor">joku ehdoista</label>

    </div>
    <input type="submit" class="btn btn-default" value="Hae" name="sbmt"/>
    {{xsrf_form_html()}}
    </form>
    </div>
    <div class="col-md-8">
    <h1>Hakutulokset</h1>
    <table class="table table-striped results">
        <thead>
            <tr>
                <th>Reitin tunnus</th>
                <th>Lupasopimustunnus</th>
                <th>Liikenteenharjoittaja</th>
                <th>Reittinimi</th>
                <th>Vuoromäärä</th>
                <th>&nbsp;</th>
            </tr>
        </thead>
        <tbody id="results">
        {% for v in reitit %}
        <tr>
            <td>{{v.reittiid}}</td>
            <td>{{v.lupasoptunnus}}</td>
            <td>{{v.liikharj_nimi}}</td>
            <td>{{v.reittinimi}}</td>
            <td>{{v.vuoromaara}}</td>
            <td>{{v.vuoron_url_interpoloitu}}</td>
        </tr>
        {% endfor %}
        </tbody>
    </table>
    </div>

{% endblock %}

{%block style %}
.results td,
.results th {
    font-size: 10px;
}
{% endblock %}
<script>
{% block script %}
$(function() {
     $('#searchform').submit(function () {
        $.post('{{ reverse_url('reitit') }}?format=json',$('#searchform').serialize(),function(d) {
            $('#results').html('');
            d.forEach(function (v) {
                $('#results').append('<tr>' +
                    '<td><a href="/joukkoliikenne/katselu/reitti/' + v.reittiid + '">' + v.reittiid + '</a></td>' +
                    '<td><a href="#' + v.lupasoptunnus + '">' + v.lupasoptunnus + '</a></td>' +
                    '<td><a href="#' + v.liikharjnro + '">' + v.liikharj_nimi + '</a></td>' +
                    '<td><a href="/joukkoliikenne/katselu/reitti/' + v.reittiid + '">' + v.reittinimi + '</a></td>' +
                    '<td>' + v.vuoromaara + '</td>' +
                    '<td><a href="' + v.vuoron_url_interpoloitu + '">Katselu</a></td>' +
                    '</tr>')
            });
        },'json');
        return false;
     });
});

{% endblock %}
</script
