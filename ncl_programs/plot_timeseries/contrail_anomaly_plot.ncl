;=======================================================;
;  contrail_anomaly_plot.ncl 
;=======================================================;
;
; Concepts illustrated:
;   - For use with MOPITT CO anomaly and average 
;     total column timeseries files
;     - loading CO anomalies
;
;   Files needed:
;         -MOPITT anomaly files
;
;   To run type:
;         ncl anomaly_plot.ncl 
;                                  RRB August 10, 2017
;=======================================================;
; load the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

;--------------------------------------------
; user input
;--------------------------------------------

  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  loc = "Siberia" ; North/SouthAustralasia, East/WestSAmerica, Central/SouthSAfrica, MaritimeSEA

  version = "V8T"
  anom_loc = "~/Dropbox/Work/CONTRAST_CO_Variability/CO_data/"
  anom_file = "CONTRAIL_CO_datatset_181016.csv"


  location_title = "CONTRAIL"
  sub_label = "(a) "
    year_s = 1994
    year_e = 2018

  ;------------
  ; toggles
  ;------------
  PLOT           = False
    plttype      = "x11"
    ;plttype@wkPaperSize = "A4"
     plttype@wkWidth = 1200
     plttype@wkHeight = 1200 
      ymin       =-5e17
      ymax       =12e17

  PLOTANNUAL    = True
    plt2type      = "x11"
     plt2type@wkWidth = 1200
     plt2type@wkHeight = 1200 
      y2min       =-7.5e17
      y2max       =9.0e17

  
;--------------------------------------------
; end user input
;--------------------------------------------
;
;--------------------------------------------
; set up
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; names of data structures
  ; determined from an ncl_filedump
  sat_tcol      = "MOPITT_CO_TCOL_FILLED"
  sat_anom      = "MOPITT_CO_ANOMALY"
  timearray     = "YYYYMM"


  ; -------------------------------
  ; OUTPUT RELATED SETUP
  ; -------------------------------
  if (PLOT) then
    pltdir       = "/IASI/home/buchholz/"
    pltname      = pltdir+version+"mopitt_l2_anomalies_" + loc
  end if

  if (PLOTANNUAL) then
    pltdir       = "/IASI/home/buchholz/"
    plt2name     = pltdir+version+"mopitt_l2_anomalies_annual_" + loc
  end if


;--------------------------------------------
; load file and extract
;--------------------------------------------
  ; -------------------------------
  ; MOPITT
  ; -------------------------------
  ; read data from region
  lines  = asciiread(anom_loc+anom_file,-1,"string")
  delim  = ","

    ncols  = dimsizes(str_split(lines(9),delim))
    nlines = dimsizes(lines)-1
    print("Columns:"+ncols+", Lines:"+nlines)

    ;---Reshape as 2D array, and convert to float for ppm/ppb/ppt.
    fields = new((/nlines,ncols/),float)
    do nf=0,ncols-1                    ;Remember that fields start at 1, not 0.
      fields(:,nf) = tofloat(str_get_field(lines(1:),nf+1,delim)) 
    end do

    mopitt_tcol    = fields(:,1)
    mopitt_anom    = fields(:,2)
    mopitt_time    = fields(:,0)        ;  YYYYMM
      split_dates = str_split_by_length(tostring(mopitt_time),4)
      years = split_dates(:,0)
      months = toint(split_dates(:,1))
      plottime = yyyymm_to_yyyyfrac(mopitt_time,0.5)

  ; -------------------------------
  ; CLIMATOLOGICAL MONTH AVERAGES 
  ; and STANDARD DEVIATION
  ; ------------------------------- 
    climate_co   = new((/12/), float)
    climate_co_sd = new((/12/), float)

  do i=0,11
     ; get indices of array related to specific month
     month_ind := ind(months.eq.(i+1))
     co_to_avg := mopitt_tcol(month_ind)

     climate_co(i) =  dim_avg_n(tofloat(co_to_avg),0)
     climate_co_sd(i) =  dim_stddev_n(tofloat(co_to_avg),0)
  end do ;i=0,dimsizes(mopitt_time)-1
  
  ; repeat climate values over total time period
  startyear = toint(years(0))
  endyear = toint(years(dimsizes(years)-1))
  climate_time = yyyymm_time(toint(startyear), toint(endyear), "integer")
  years_of_record = endyear - startyear
   climate_co_ext    = new((/toint(years_of_record+1)*12/), float)
   climate_co_sd_ext = new((/toint(years_of_record+1)*12/), float)

  do y = 0, years_of_record
    do m=0,11
     climate_co_ext(y*12+m) = climate_co(m)
     climate_co_sd_ext(y*12+m) = climate_co_sd(m)
    end do
  end do

printVarSummary(climate_co_ext)
printVarSummary(mopitt_anom)
rel_anomalies = mopitt_anom/climate_co_ext
print("Range of anomalies:")
print(min(mopitt_anom)+" to " + max(mopitt_anom))
print("...relative to climatological mean month values...")
print(min(rel_anomalies)+" to " + max(rel_anomalies))

;--------------------------------------------
; plot
;--------------------------------------------
if (PLOT) then

  wks = gsn_open_wks(plttype,pltname)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                       = True                      ; plot mods desired
    res@gsnDraw		    = False	                ; don't draw it yet
    res@gsnFrame            = False                     ; don't advance frame
    res@gsnMaximize         = True

    res@vpWidthF             = 1.8
    res@vpHeightF            = 0.45                      ; set height of plot

    res@tmBorderThicknessF  = 3
    res@tmXBMajorThicknessF = 3
    res@tmYLMajorThicknessF = 3

    res@tmYLMajorOutwardLengthF = 0.0                    ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0                    ; draw minor ticsk inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0   

    res@trXMinF             = year_s
    res@trXMaxF             = year_e

    res@tmXBLabelsOn          = False
    res@tmXBLabelFontHeightF  = 0.048
    res@tmYLLabelFontHeightF  = 0.048
    res@tiYAxisFontHeightF    = 0.052
    res@tiXAxisFontHeightF    = 0.052

    res@tiMainString           = ""
    res@tiXAxisString          = ""

    res@pmLegendDisplayMode      = "Always"               ; turn on legend
      res@lgPerimOn                = False               ; Turn off perimeter
      res@pmLegendWidthF           = 0.20                ; Change width and
      res@pmLegendHeightF          = 0.50                ; height of legend
      res@lgLabelFontHeightF       = 0.048


  ; ===================
  ; timeseries plot
  ; averages and climatology
  ; ===================
  ; MOPITT
  ;  res@tmYLMode            = "Explicit"
  ;    res@trYMinF             = 1e18
  ;    res@trYMaxF             = 3.6e18
  ;    res@tmYLValues          = fspan(1e18,3.5e18,6)
  ;    res@tmYLLabels          = fspan(1e18,3.5e18,6)/1e18
  ;    res@tmYLMinorValues     = fspan(1e18,3.5e18,11)

    res@tiYAxisString       = "CO Column"
    res@gsnRightString      = "" 
    res@xyMarkLineMode      = "Markers"
    res@xyMarker            = 17
    res@xyMarkerSizeF       = 0.08
    res@xyMarkerColor       = "grey34"
    res@xyExplicitLegendLabels   = "Month average"
    res@pmLegendOrthogonalPosF = -1.7
    res@pmLegendParallelPosF   = 0.475
   plot1 = gsn_csm_xy(wks,plottime,mopitt_tcol,res)

    res@gsnRightString         = "~F34~4~F21~10~S2~18   molec. cm~S2~-2" 
    res@xyMarkLineMode         = "Lines"
    res@xyLineThicknessF       = 7.0
    res@xyLineColor            = "black"
    res@xyExplicitLegendLabels = "Seasonal cycle"
    res@pmLegendOrthogonalPosF = -1.85
    res@pmLegendParallelPosF   = 0.475
   plot2 = gsn_csm_xy(wks,plottime,climate_co_ext,res)
   overlay(plot1, plot2)


  ; ===================
  ; Anomaly plot
  ; ===================
    res@pmLegendDisplayMode  = "Never"               ; turn off legend
    res@vpHeightF            = 0.3                       ; set height of plot
    res@xyLineThicknessF     = 1.5
    res@tiYAxisString        = "Anomaly"
    res@gsnRightString        = "" 
    res@xyLineColor          = "black"

    ;res@tmYLMode             = "Explicit"
    ;  res@trYMinF             := ymin-0.05e18
    ;  res@trYMaxF             := ymax+0.05e18
    ;  res@tmYLValues          := (/-0.5e18, 0.0, 0.5e18/)
    ;  res@tmYLLabels          := (/-0.5, 0, 0.5/)
    ;  res@tmYLMinorValues     := (/-0.25e18, 0.25e18/)

    res@tmXBLabelsOn          = True
    res@tmXBMode              = "Explicit"
      res@tmXBValues           = tofloat(ispan(year_s,year_e,3))
      res@tmXBLabels           = tofloat(ispan(year_s,year_e,3))
      res@tmXBMinorValues      = tofloat(ispan(year_s,year_e,1))
    res@tiXAxisString          = "Year"

    res@gsnRightString       = ""

   res@gsnYRefLine      = 0.0
   res@gsnAboveYRefLineColor = "wheat2"                  ; above ref line fill red
   res@gsnBelowYRefLineColor = "limegreen"               ; below ref line fill blue

  plot3 = gsn_csm_xy(wks,plottime,mopitt_anom,res)


  ; add zero line
   res_lines                   = True                     ; polyline mods desired
     res_lines@gsLineDashPattern = 0                      ; line style
     res_lines@gsLineThicknessF  = 2.5                    ; line thicker
     res_lines@gsLineColor       = "black"                ; line color
     res_lines@tfPolyDrawOrder   = "PreDraw"              ; send to back
   xx = (/year_s,year_e/)
   yy = (/0,0/)
  dum3 = gsn_add_polyline(wks,plot3,xx,yy,res_lines)      ; add polyline

  ; -------------------------------
  ; Add random error
  ; -------------------------------
   ya1    = new( (/2*dimsizes(plottime)/), double )
   yb1    = new( (/2*dimsizes(plottime)/), double )
   do k=0,dimsizes(plottime)-1
     ya1(k) = plottime(k)
     yb1(k) = 1.0e16
     yb1(2*dimsizes(plottime)-1-k) = 0-1.0e16
     ya1(2*dimsizes(plottime)-1-k) = plottime(k)
   end do
    gsres                          = True         ; poly res
    gsres@gsFillColor              = "black"       ; color chosen
    gsres@gsFillOpacityF           = 0.6                 
    dum3 = gsn_add_polygon(wks,plot3,ya1,yb1,gsres)

  ; -------------------------------
  ; Define a polygon for std-dev
  ; -------------------------------
   ya1    = new( (/2*dimsizes(plottime)/), float )
   yb1    = new( (/2*dimsizes(plottime)/), float )
   do k=0,dimsizes(plottime)-1
     ya1(k) = plottime(k)
     yb1(k) = climate_co_sd_ext(k)
     yb1(2*dimsizes(plottime)-1-k) = 0-climate_co_sd_ext(k)
     ya1(2*dimsizes(plottime)-1-k) = plottime(k)
   end do
    gsres                          = True                ; poly res
    gsres@gsFillColor            = "grey"                ; color chosen
    gsres@gsFillOpacityF         = 0.4                 
    ;dum2 = gsn_add_polygon(wks,plot3,ya1,yb1,gsres)

  ; -------------------------------
  ; panel the plots
  ; -------------------------------
  res1                     = True
    res1@gsnAttachBorderOn   = False
  res2                     = True
    res2@gsnMaximize         = True
    res2@gsnAttachPlotsXAxis = True

  ; plot1 will be the base plot.
  amid = gsn_attach_plots(plot1,plot3,res1,res2)

  ;-----------------------------------
  ; Add in title and labels
  ;-----------------------------------
   ;drawNDCGrid(wks)
   ; add station
    txres                   = True                      ; polyline mods desired
     txres@txFontHeightF    = 0.024                     ; font smaller. default big
     txres@txJust           = "CenterLeft"              ; font smaller. default big
     txres@txPerimOn        = True
     txres@txPerimThicknessF= 2.0
    ;gsn_text_ndc(wks,location_title,0.155,0.71,txres)
    gsn_text_ndc(wks,location_title,0.155,0.67,txres)
     txres@txPerimOn        = False
    ;gsn_text_ndc(wks,"(c)",0.17,0.64,txres)
    ;gsn_text_ndc(wks,"(d)",0.17,0.43,txres)
    gsn_text_ndc(wks,"(a)",0.17,0.60,txres)
    gsn_text_ndc(wks,"(b)",0.17,0.39,txres)

  draw(plot1)
  frame(wks)

end if ; PLOT


if (PLOTANNUAL) then

  ; ===================
  ; Collect anomaly data
  ; into 12 month chunks
  ; ===================
  month_points := tofloat(ispan(1,12,1))
  plot_data = new((/(year_e-1995),12/),float)
  do y = 0, (year_e-1995-1)
    first_ind = y*12
    last_ind = (y*12)+11
    plot_data(y,:) = tofloat(mopitt_anom(first_ind:last_ind))
  end do

  ; ===================
  ; Open plot
  ; ===================
  wks = gsn_open_wks(plt2type,plt2name)        
  gsn_define_colormap(wks,"BlAqGrYeOrRe")  
   
  res                         = True                     ; plot mods desired
    res@gsnDraw		      = False	                 ; don't draw it yet
    res@gsnFrame              = False                    ; don't advance frame
    res@gsnMaximize           = True

    res@tmXBLabelFontHeightF  = 0.028
    res@tmYLLabelFontHeightF  = 0.028
    res@tiYAxisFontHeightF    = 0.034
    res@tiXAxisFontHeightF    = 0.034

    res@tmYLMajorOutwardLengthF = 0.0                    ; draw tickmarks inward
    res@tmYLMinorOutwardLengthF = 0.0                    ; draw minor ticsk inward
    res@tmXBMajorOutwardLengthF = 0.0               
    res@tmXBMinorOutwardLengthF = 0.0  

    res@tmBorderThicknessF     = 3
    res@tmXBMajorThicknessF    = 3
    res@tmYLMajorThicknessF    = 3

    res@vpWidthF             = 0.85
    res@vpHeightF            = 0.4

    res@pmLegendDisplayMode      = "Never"        ; turn on legend
      res@lgPerimOn                = False           ; Turn off perimeter
      res@pmLegendWidthF           = 0.15            ; Change width and
      res@pmLegendHeightF          = 0.4             ; height of legend
      res@lgLabelFontHeightF       = 0.020
      ;res@xyExplicitLegendLabels   = tofloat(ispan(2001,year_e,1))


  ; ===================
  ; Annual anomaly plot
  ; ===================
    res@xyMarkLineMode      = "Marklines"
    res@xyMarker            = 17
    res@xyMarkerSizeF       = 0.04
    res@xyLineThicknessF    = 7

    ;res@tiYAxisString       = "CO Anomaly (~F34~4~F21~10~S2~18   molec. cm~S2~-2  )"
    res@tiYAxisString       = "CO Anomaly"
    ;res@trYMaxF             := 40.
    ;res@tmYLMode            = "Explicit"
      ;res@trYMinF             := y2min-0.05e18
      ;res@trYMaxF             := y2max+0.05e18
      ;res@tmYLValues          := (/-0.5e18, 0.0, 0.5e18, 1.0e18/)
      ;res@tmYLLabels          := (/"-0.5","0","0.5", "1.0"/)
      ;res@tmYLMinorValues     := (/-0.25e18, 0.25e18, 0.75e18/)

    res@tiXAxisString       = "Month of year"
    res@tmXBLabelAngleF     = -45.0
    res@tmXBMode            = "Explicit"
      res@trXMinF             := 0.5
      res@trXMaxF             := 12.5
      res@tmXBValues         = month_points
      res@tmXBLabels         = (/"Jan", "Feb", "Mar", "Apr", "May", "Jun", \
                                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"/)

    res@xyDashPatterns      = (/0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0/)
    res@xyLineColors        = (/"red4","red2","darkorange3","orange","gold","olivedrab1",\
                               "limegreen", "forestgreen","darkgreen","seagreen2","cyan2",\
                               "cornflowerblue","blue","navy","purple4", "black", "gray90",\
                               "gray80", "gray70", "gray60", "gray50", "gray40","gray30"/)
    res@xyMarkerColors      = (/"red4","red2","darkorange3","orange","gold","olivedrab1",\
                              "limegreen","forestgreen","darkgreen","seagreen2","cyan2",\
                               "cornflowerblue","blue","navy","purple4", "black", "gray90",\
                               "gray80", "gray70", "gray60", "gray50", "gray40","gray30"/)

   ; Create the plot
   plot = gsn_csm_xy(wks,month_points,plot_data,res)

 ; add zero line
  res_lines                   = True                     ; polyline mods desired
    res_lines@gsLineDashPattern = 0                 ; line style
    res_lines@gsLineThicknessF  = 4.5                     ; line thicker
    res_lines@gsLineColor       = "black"                 ; line color
    res_lines@tfPolyDrawOrder   = "PreDraw"              ; send to back
  xx2 = (/0,13/)
  yy2 = (/0,0/)
  dum3 = gsn_add_polyline(wks,plot,xx2,yy2,res_lines)      ; add polyline

  ;-----------------------------------
  ; Add in title
  ;-----------------------------------
   ;drawNDCGrid(wks)
   ; add station
    txres                   = True                     ; polyline mods desired
     txres@txFontHeightF    = 0.028                   ; font smaller. default big
     txres@txJust           = "CenterLeft"             ; font smaller. default big
     txres@txPerimOn        = True
     txres@txPerimThicknessF= 2.0
    gsn_text_ndc(wks,sub_label+location_title,0.22,0.70,txres)

  draw(plot)
  frame(wks)

end if; PLOTANNUAL




end

