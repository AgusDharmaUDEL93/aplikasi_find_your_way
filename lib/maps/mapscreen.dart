import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  static const _initialCameraPosition = CameraPosition(
      target: LatLng(-8.7119416, 115.1988696),
      zoom: 11.5
  );

  int id = 1;

  List<int> rute = [];
  Set<Marker> markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> polyCordinates = [];

  late GoogleMapController _googleMapController;
  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            polylines: _polylines,
            onLongPress: (latLng){
              Marker newMarker = Marker(markerId: MarkerId('$id'),
                position: LatLng(latLng.latitude, latLng.longitude),
                infoWindow: InfoWindow(title: 'Destination $id'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue
                )
              );
              markers.add(newMarker);
              polyCordinates.add(LatLng(latLng.latitude, latLng.longitude));
              id++;
              setState(() {

              });
            },
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) async {
              Position position = await _determinePosition();
              markers.add(
                  Marker(
                    markerId: const MarkerId('0'),
                    position: LatLng(position.latitude, position.longitude),
                    infoWindow: const InfoWindow(title: 'Your Location'),
                  )
              );
              polyCordinates.add(LatLng(position.latitude, position.longitude));
              setState(() {

              });
              _googleMapController = controller;
            },
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.black,
              onPressed: () async {
                id = 1;
                markers.clear();
                polyCordinates.clear();
                rute.clear();
                Position position = await _determinePosition();
                markers.add(Marker(markerId: const MarkerId('0'), position: LatLng(position.latitude, position.longitude)));
                polyCordinates.add(LatLng(position.latitude, position.longitude));
                setState(() {

                });
              },
              child: const Icon(Icons.delete_outlined),
            ),
          ),
          Positioned(
            bottom: 25,
            left: 120,
            right: 120,
            child: Container(
              height: 37,
              width: 100,
              alignment: Alignment.bottomCenter,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                color: Colors.white
              ),
              child: TextButton(
                  onPressed: (){
                    algorithm();
                    dialog(context);
                  },
                  child: const Text('A N A L Y S T'),
              ),
            ),
          )
      ]
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.black,
        onPressed: () async {
          Position position = await _determinePosition();
          _googleMapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 11.5)));
          setState(() {});
        },
        child: const Icon(Icons.center_focus_strong),
      ),

    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if(!serviceEnabled){
      return Future.error("Location Not Granted!");
    }

    permission = await Geolocator.checkPermission();

    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied){
        return Future.error("Location Not Granted!");
      }
    }
    if (permission == LocationPermission.deniedForever){
      return Future.error("Location permission are permanently denied!");
    }

    Position position = await Geolocator.getCurrentPosition();
    return position;


  }

  algorithm() {
    var size = markers.length;
    var matriks = List.generate(size, (index) => List.filled(size, 9999.00), growable: false);
    rute.clear();
    for(int i = 0; i < size; i++){
      for(int j = 0; j < size; j++){
        if (i == j) {
          matriks[i][j] = 0;
        } else {
          matriks[i][j] = _coordinatedDistance(polyCordinates[i].latitude, polyCordinates[i].longitude, polyCordinates[j].latitude, polyCordinates[j].longitude);
        }
      }
    }
    var i = 0;
    rute.add(i);
    var pendek = 99.0;

    while (rute.length < size-1){
      for (int j = 0 ; j < size ; j++){
        if (!rute.contains(j)){
          if (pendek > matriks[i][j]) {
            pendek = matriks[i][j];
          }
        }
      }

      for (int k = 0; k < size; k++){
        if (matriks[i][k] == pendek){
          rute.add(k);
          pendek = 99.0;
          i = k;
        }
      }
    }

    for (int j = 0; j <size; j++){
      if (!rute.contains(j) ){
        rute.add(j);
      }
    }
  }

  _coordinatedDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2-lat1) * p ) / 2 + cos((lat1*p)) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  dialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
       child: Padding(
         padding: const EdgeInsets.all(27.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           mainAxisSize: MainAxisSize.min,
           children:  [
             const SizedBox(
               height: 30,
             ),
             const Center(
               child: Icon(
                 Icons.flag_circle_outlined,
                 size: 30,
               ),
             ),
             const SizedBox(
               height: 10,
             ),
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: const [
                 Text(
                   "DATA",
                   style: TextStyle(
                     fontSize: 20
                   ),
                 ),
                 SizedBox(
                   width: 5,
                 ),
                 Text(
                   "ANALYST",
                   style: TextStyle(
                     color: Colors.blue,
                     fontSize: 20
                   ),
                 )
               ],
             ),
             const SizedBox(
               height: 50,
             ),
             const Text(
               'Best Route',
               style: TextStyle(
                 fontSize: 18,
                 fontWeight: FontWeight.bold
               ),
             ),
             Text(
               '$rute',
               style: const TextStyle(
                 fontSize: 16,
               ),
             ),
             const SizedBox(
               height: 30,
             ),
             const Text(
               'Noted',
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold
               ),
             ),
             const Text(
               '0 is yout position',
               style: TextStyle(
                 fontSize: 12,
               ),
             ),
             const SizedBox(
               height: 30,
             ),
             Center(
               child: ElevatedButton(
                 child: const Text('Close'),
                 onPressed: () => Navigator.of(context).pop(),
               ),
             ),
             const SizedBox(
               height: 30,
             ),
           ],
         ),
       ),
      )
  );
}

