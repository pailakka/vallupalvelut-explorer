{% extends "base.tpl" %}


{% block title %}Reitit{% endblock %}
{% block content %}
<div class="row">
    <div class="col-md-12">
        <h1>Reitin tiedot</h1>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <h2>Perustiedot</h2>
        <h3>Lupa/Sopimus</h3>
        <table class="table table-striped">
            <tr>
                <th>Lupa- / sopimustunnus</th>
                <td><a href="#{{reitti.lupasoptunnus}}">{{reitti.lupasoptunnus}}</a>
                </td>
            </tr>
            <tr>
                <th>Myöntäjä</th>
                <td>{{reitti.viranomaisnimi}} ({{reitti.lu_viranro_myontaa}})</td>
            </tr>
            <tr>
                <th>Valvoja</th>
                <td>{{reitti.viranomaisnimi_1}} ({{reitti.lu_viranro_valvoo}})</td>
            </tr>
            <tr>
                <th>Voimaan</th>
                <td>{{reitti.lu_voim_pvm}}</td>
            </tr>
            <tr>
                <th>Päättyy</th>
                <td>{{reitti.lu_tod_loppvm}}</td>
            </tr>
            <tr>
                <th>Muokattu</th>
                <td>{{reitti.muokattu_pvm}}</td>
            </tr>
        </table>
        <h3>Reitti</h3>
        <table class="table table-striped">
            <tr>
                <th>Nimi</th>
                <td>{{reitti.reittinimi}}</td>
            </tr>
            <tr>
                <th>Tunnus</th>
                <td>{{reitti.reittinro_pysyva}}</td>
            </tr>
            <tr>
                <th>Liik. harj</th>
                <td><a href="#{{reitti.liikharjnro}}">{{reitti.liikharj_nimi}}</a> ({{reitti.liikharjnro}})</td>
            </tr>
            <tr>
                <th>Voimaan</th>
                <td>{{reitti.reitti_voimaan_pvm}}</td>
            </tr>
            <tr>
                <th>Päättyy</th>
                <td>{{reitti.reitti_paattyy_pvm}}</td>
            </tr>
            <tr>
                <th>Muokattu</th>
                <td>{{reitti.reittia_muokattu_pvm}}</td>
            </tr>
        </table>
    </div>
    <div class="col-md-9">
        <div class="row">
            <div class="col-md-12">
                <h2>Pysäkkiketju</h2>
                <table class="table table-striped table-condensed table-bordered stationlist">
                <thead>
                {#
                    <tr>
                        <th colspan="4">&nbsp;</th>

                        {% for k in kaudet %}
                        <th colspan="{{kaudet[k]|length}}">{{k}}</th>
                        {%endfor%}
                        <th>&nbsp;</th>

                    </tr>

                    #}
                    <tr>
                        <th>Ix</th>
                        <th>Nimi</th>
                        <th>Vk. tunnus</th>
                        <th>Aikapiste</th>
                        {#
                        {% for k in kaudet %}
                        {% for vm in kaudet[k] %}
                        <th>{{vm}}</th>
                        {% endfor %}
                        {% endfor %}
                        #}
                        <th>Etäisyys</th>
                        <th>Etäisyys kuml.</th>
                    </tr>
                </thead>
                <tbody>
                {% set totdist = 0%}
                {% for v in vuorot if v.has_stops%}
                {%if loop.index0 == 0 %}
                {% for s in v.stops %}

                <tr>
                    <td>{{s.jarj_nro}}</td>
                    <td><a href="#{{s.valtakid if s.valtakid != None else 'V%d' % s.gid}}">{{s.nimi}}</a></td>
                    <td><a href="#{{s.valtakid if s.valtakid != None else 'V%d' % s.gid}}">{{s.valtakid if s.valtakid else ''}}</a></td>
                    <td>{% if s.aikapiste%}Kyllä{%else%}Ei{%endif%}</td>
                    {#
                    {%for k in kaudet %}{%for vm in kaudet[k]|sort%}{% if s.nk%}<td>{% for s in nopeudet[s.nk][k][vm]%}{%if not loop.first%} / {%endif%}+{{s}} min{%endfor%}</td>{%else%}<td>&nbsp;</td>{%endif%}{% endfor %}{% endfor %}
                    #}
                    <td>{%if s.nk %}{{etaisyydet[s.nk]|round(1)}} km{%else%}0.0km{%endif%}</td>
                    <td>{%if s.nk %}{% set totdist = totdist+etaisyydet[s.nk]%}{{totdist|round(1)}} km{%else%}0.0km{%endif%}</td>

                {%endfor%}
                {%endif%}
                {%endfor%}
                </tbody>
                </table>
            </div>
        </div>
        <div class="row">
            <div class="col-md-12">
                <h2>Vuorot</h2>
                <table class="table table-striped table-condensed table-bordered servicelist table-hover">
                <thead>
                    <tr>
                        <th colspan="2">Vuorotunniste</th>
                        <th colspan="12">&nbsp;</th>
                    </tr>
                    <tr>
                        <th>Pysyvä</th>
                        <th>Lisä</th>
                        <th>Tyyppi</th>
                        <th>Kausi</th>
                        <th>Vuorom.</th>
                        <th>Suunta</th>
                        <th>Lähtö</th>
                        <th>Perillä</th>
                        <th>Kesto</th>
                        <th>Voimaan</th>
                        <th>Päättyy</th>
                        <th>Muokattu</th>
                        <th>Käsit.</th>
                        <th>&nbsp;</th>
                    </tr>
                </thead>
                <tbody>
                    {%for v in vuorot%}
                    <tr>
                        <td>{{v.vuorotunniste_pysyva}}</td>
                        <td>{{v.vuoro_lisatunniste}}</td>
                        <td>{{v.vuorotyyppi}}</td>
                        <td>{{v.kausi}}</td>
                        <td>{{v.vuoromerk}}</td>
                        <td>{{v.ajosuunta}}</td>
                        <td>{%if v.has_stops %}{{v.stops.0.departuredt.strftime('%H:%M')}}{%endif%}</td>
                        <td>{%if v.has_stops %}{{v.stops[-1].arrivaldt.strftime('%H:%M')}}{%endif%}</td>
                        <td>{{v.kesto}}</td>
                        <td>{{v.vuoro_voimaan_pvm}}</td>
                        <td>{{v.vuoro_paattyy_pvm}}</td>
                        <td>{{v.vuoroa_muokattu_pvm}}</td>
                        <td>{%if v.kasitelty_koontikartassa == 1%}Kyllä{%else%}Ei{%endif%}</td>
                        <td><a href="{{v.vuoron_url_interpoloitu}}">Katselu</a></td>
                    </tr>
                    {%endfor%}
                </tbody>
                </table>
            </div>
        </div>
    </div>

</div>

{% endblock %}

{%block style %}
table td,
table th {
    font-size:12px;
}


{% endblock %}
<script>
{% block script %}
$(function() {
});
{% endblock %}
</script>
