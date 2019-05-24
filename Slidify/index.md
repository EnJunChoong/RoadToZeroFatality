---
title       : Road to Zero Fatality                            
subtitle    : A Visualization Tool on UK Fatal Accidents 
author1     : Choong En Jun   WQD180113
author2     : Chan Swee Tat   WQD180092
author3     : Yew Kwang Yong  WQD180091
author4     : Kak D-Wing      WQD180125
affiliation : Masters in Data Science, University of Malaya
framework   : io2012      # {io2012, html5slides, shower, dzslides, ...}
highlighter : highlight.js  # {highlight.js, prettify, highlight}
hitheme     : tomorrow      # 
widgets     : []            # {mathjax, quiz, bootstrap}
mode        : selfcontained # {standalone, draft}
knit        : slidify::knit2slides
github:
    user: EnJunChoong
    repo: RoadToZeroFatality


--- .class #intro bg:#c6c5e2
## Introduction

<style>
strong {
  font-weight: bold;
}
</style>

<html><p><img style="padding: 0 15px; float: left;" src="Intro.jpg"><span style="font-size: 12pt;">In 2015, the UN rolled out the <strong>2030 Agenda for Sustainable Development</strong>.In Sustainable Development Goals 3.6, the UN is committed to halve the road accident fatalities and injuries world wide.&nbsp;</span></p>
<blockquote>
<p style="text-align: center;"><strong><span style="font-family: verdana, geneva; font-size: 16pt;">"SDG 3.6: By 2020, halve the number of global deaths and injuries from road traffic accidents."</span></strong></p>
</blockquote>
<p><span style="font-size: 12pt;"> This Shiny application is created in 2019, within one year before the proposed deadline. The 2005-2015 UK road Accident dataset is obtained from: https://www.kaggle.com/silicon99/dft-accident-data. This app offer the UK public a visualization tool on the fatal road accidents in UK and the infographics associated with them. &nbsp;</span></p></html>
<p><span style="font-size: 12pt;"> In the following slides, we will discuss on our <strong>Data Science Process</strong>, <strong>App Description</strong> and our <strong>Experience</strong>. &nbsp;</span></p></html>


--- .class #process bg:#c6c5e2
## Data Science Process
<strong>Asking an interesting question:</strong><br>
In conjunction with UN Sustainable Development Goals 3.6, we want to know what is the historical trend and infographic associated with Fatal Road Accidents in UK. 

<strong>Get the Data:</strong><br>
The 2005-2015 UK road Accident dataset contained all road accidents reported. <br>
https://www.kaggle.com/silicon99/dft-accident-data.

<strong>Explore the Data:</strong><br>
head(), summary(), str(), and boxplot() are used to understand dataset, identify missing values, and gauge fittings of the data.


<strong>Model the Data:</strong><br>
Data is cleaned, integrated and transformed in order to work with shiny and visualization tools.

<strong>Communicate and Visualize the result:</strong><br>
Data visualization is available on github and shiny io, slides on rpubs. 


--- &twocol #app bg:#c6c5e2
## App Description
Our Shiny app consists of two tabs. One for map visualization, and the other for chart visualization. Our final dataset is filtered to only show accidents involving fatalities. 
***=left
<img src="Map.gif",height="100%", width="100%">

***=right
<img src="Chart.gif",height="100%", width="100%">


--- .class #id bg:#c6c5e2
## Experience
As with all new learning experience, we had our struggles with getting things to work. We learned the hard way that the code that worked on our local machine does not necessarily work on the cloud server. There are always little bit and pieces of details that can go wrong. 

Visualization is an important tool for all data scientist. We are glad that we have a new tool handy in our pocket now. 

Link to our app is as follow:<br>
  Shiny App: https://enjunz.shinyapps.io/uk_fatal_accidents_2005-2015_visualization/<br>






