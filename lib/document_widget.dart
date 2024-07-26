import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:weather_animation/weather_animation.dart';

class DocumentWidget extends StatelessWidget {
  const DocumentWidget({
    Key? key,
    required this.document,
  }) : super(key: key);

  final Document document;

  @override
  Widget build(BuildContext context) {
                                  return Theme(
                                    data: ThemeData(
                                      textTheme: TextTheme(
                                        titleMedium: TextStyle(fontSize: 18,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer),

                                      )
                                    ),
                                    
                                    child: Stack(
                                      children:[ SizedBox(
                                        width: MediaQuery.of(context).size.width,
                                        height: 70.0,
                                        child: 
                                        WrapperScene(
    sizeCanvas: Size(MediaQuery.of(context).size.width-20, 30),
    isLeftCornerGradient: true,
    colors: [
      Color(0xff283593),
Color(0xff283593),
],
    children: [
      document.symbolCode == 'fair_day'
        ? SunWidget(
            sunConfig: SunConfig(
              width: 150,
              blurSigma: 10.0,
              blurStyle: BlurStyle.solid,
              isLeftLocation: false,
              coreColor: Color(0xffffa726),
              midColor: Color(0xd6ffee58),
              outColor: Color(0xffff9800),
              animMidMill: 2000,
              animOutMill: 1800,
            ),
          )
        : document.symbolCode == 'cloudy'
            ? CloudWidget(
                cloudConfig: CloudConfig(
                  size: 100, color: Color(0xaaffffff), icon: IconData(63056, fontFamily: 'MaterialIcons'), widgetCloud: null, x: 70, y: 5, scaleBegin: 1, scaleEnd: 1.1, scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00), slideX: 11, slideY: 5, slideDurMill: 2000, slideCurve: Cubic(0.40, 0.00, 0.20, 1.00)),
                
              )
              : document.symbolCode == 'partlycloudy_day'
            ? CloudWidget(
                cloudConfig: CloudConfig(
                  size: 50, color: Color(0xaaffffff), icon: IconData(63056, fontFamily: 'MaterialIcons'), widgetCloud: null, x: 120, y: 5, scaleBegin: 1, scaleEnd: 1.1, scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00), slideX: 11, slideY: 5, slideDurMill: 2000, slideCurve: Cubic(0.40, 0.00, 0.20, 1.00)),
                
              )
            : Container(),

                                      Column(
                                      children: [  
                                           Theme(
                                            data: Theme.of(context).copyWith(
                                              textTheme: TextTheme(
                                                titleMedium: TextStyle(fontSize: 18,
                                                    color: Colors.white),
                                              ),
                                            iconTheme: IconThemeData(
                                              color: Colors.white,
                                            ),),
                                            
                                          
                                          child: ListTile(
                                            
                                            leading: Text(
                                              '${document.time}',
                                              //make text black with a white stroke
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontSize: 26.0,
                                          
                                              
                                              ),
                                          
                                             
                                          
                                                                                     
                                            ),
                                            title: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                              
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(' ${document.windSpeed} m/s '),
                                                          Icon(Icons.air),
                                          
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(' ${document.airTemperature}°C '),
                                                          Icon(Icons.thermostat_outlined),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(padding: EdgeInsets.only(left: 24.0)),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      
                                                      Row(
                                                        children: [
                                                          Text(' ${document.precipitationProbability}%'),
                                                          Icon(Icons.umbrella),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(' ${document.availableSlots} '),
                                                          Icon(Icons.sports_baseball),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                            ),
                                          ),
                                        ),
                                        
                                      ],
                                    ),

                                        
                                        
                                      ],
                                    ),
                                  ),
                                    ],
                                    ),
                                  );
                                }

}
