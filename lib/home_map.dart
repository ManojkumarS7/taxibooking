import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;


class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _showDestinationBanner = false;
  RouteDetails? _currentRoute;
  LatLng? _selectedDestination;
  String _selectedDestinationName = '';
  bool _cabBooked = false;
  bool _cabArriving = false;

  // Search and autocomplete related
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<PlacePrediction> _placePredictions = [];
  bool _showPredictions = false;
  Timer? _debounce;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _passengerController = TextEditingController();

  // Replace with your actual Google Places API key
  static const String _apiKey = 'AIzaSyBPhbqYM6ypaRkOSJgKxrthxQQN5rUWDYA';

  // Default location (New York City)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(40.7128, -74.0060),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _requestPermissionAndGetLocation();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty && _searchController.text.length > 2) {
        _getPlacePredictions(_searchController.text);
      } else {
        setState(() {
          _placePredictions.clear();
          _showPredictions = false;
        });
      }
    });
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      // Hide predictions when search bar loses focus after a delay
      Timer(const Duration(milliseconds: 200), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          setState(() {
            _showPredictions = false;
          });
        }
      });
    } else {
      // Show predictions when focused if we have results
      if (_placePredictions.isNotEmpty) {
        setState(() {
          _showPredictions = true;
        });
      }
    }
  }

  void _handleDestinationSelected(PlacePrediction prediction, LatLng position, RouteDetails? routeDetails) {
    setState(() {
      _selectedDestination = position;
      _selectedDestinationName = prediction.mainText;
      _currentRoute = routeDetails;
      _showDestinationBanner = routeDetails != null;
      _cabBooked = false;
      _cabArriving = false;
    });
  }

  // Add this method to handle cab booking
  void _bookCab() {
    setState(() {
      _cabBooked = true;
      _cabArriving = true;
      _showDestinationBanner = false;
    });

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passengerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter number of passengers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int? passengers = int.tryParse(_passengerController.text);
    if (passengers == null || passengers <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of passengers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation
    _showSnackBar('Cab booked successfully!');

    // Simulate cab arrival (remove this timer in production)
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _showSnackBar('Your cab is arriving soon...');
      }
    });
  }

  // Add this method to dismiss the banner
  void _dismissDestinationBanner() {
    setState(() {
      _showDestinationBanner = false;
      _selectedDestination = null;
      _selectedDestinationName = '';
      _currentRoute = null;
    });
  }

  // Add this method to dismiss cab status
  void _dismissCabStatus() {
    setState(() {
      _cabArriving = false;
      _cabBooked = false;
    });
  }

  Future<void> _getPlacePredictions(String input) async {
    if (input.isEmpty || input.length < 3) return;

    // Use current location for better results if available
    String locationBias = '';
    if (_currentPosition != null) {
      locationBias = '"locationBias": {"circle": {"center": {"latitude": ${_currentPosition!.latitude}, "longitude": ${_currentPosition!.longitude}}, "radius": 50000}},';
    }

    // New Places API (Text Search) endpoint
    final String url = 'https://places.googleapis.com/v1/places:searchText';

    final Map<String, dynamic> requestBody = {
      "textQuery": input,
      "maxResultCount": 10,
      "locationBias": _currentPosition != null ? {
        "circle": {
          "center": {
            "latitude": _currentPosition!.latitude,
            "longitude": _currentPosition!.longitude
          },
          "radius": 50000
        }
      } : null,
    };

    // Remove null values
    requestBody.removeWhere((key, value) => value == null);

    try {
      print('Making request to: $url'); // Debug log
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location',
        },
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['places'] != null) {
          final List places = data['places'];
          setState(() {
            _placePredictions = places
                .map((place) => PlacePrediction.fromNewApiJson(place))
                .toList();
            _showPredictions = true;
          });
        } else {
          setState(() {
            _placePredictions.clear();
            _showPredictions = false;
          });
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error body: ${response.body}');
        _showSnackBar('Network error occurred');
      }
    } catch (e) {
      print('Error fetching place predictions: $e');
      _showSnackBar('Error searching places');
    }
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    setState(() {
      _showPredictions = false;
      _isLoading = true;
    });

    _searchController.text = prediction.description;
    _searchFocusNode.unfocus();

    try {
      final LatLng latLng = LatLng(prediction.latitude!, prediction.longitude!);

      if (_controller != null) {
        await _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 16),
          ),
        );
      }

      setState(() {
        _markers.removeWhere((marker) =>
            marker.markerId.value.startsWith('search_'));

        _markers.add(
          Marker(
            markerId: const MarkerId('search_result'),
            position: latLng,
            infoWindow: InfoWindow(
              title: prediction.mainText,
              snippet: prediction.secondaryText,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      });

      // Get route details if current location is available
      RouteDetails? routeDetails;
      if (_currentPosition != null) {
        routeDetails = await _getDirections(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          latLng,
        );
      }

      // Handle destination selection with route details
      _handleDestinationSelected(prediction, latLng, routeDetails);

      _showSnackBar('Location found: ${prediction.mainText}');
    } catch (e) {
      print('Error selecting place: $e');
      _showSnackBar('Error selecting place');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissionAndGetLocation() async {
    try {
      PermissionStatus permission = await Permission.location.request();

      if (permission.isGranted) {
        await _getCurrentLocation();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showPermissionDialog();
      }
    } catch (e) {
      print('Error requesting permission: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Move camera to current location
      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16,
            ),
          ),
        );
      }

      // Add marker for current location
      _addCurrentLocationMarker();
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(
                _currentPosition!.latitude, _currentPosition!.longitude),
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'You are here!',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue),
          ),
        );
      });
    }
  }

  void _onMapTapped(LatLng position) {
    // Hide predictions and unfocus search when map is tapped
    setState(() {
      _showPredictions = false;
    });
    _searchFocusNode.unfocus();

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('marker_${DateTime.now().millisecondsSinceEpoch}'),
          position: position,
          infoWindow: InfoWindow(
            title: 'Custom Marker',
            snippet: 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
          ),
          onTap: () => _showMarkerDialog(position),
        ),
      );
    });
  }

  void _showMarkerDialog(LatLng position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Marker Details'),
          content: Text(
            'Latitude: ${position.latitude.toStringAsFixed(6)}\n'
                'Longitude: ${position.longitude.toStringAsFixed(6)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Get route details for cab booking
                if (_currentPosition != null) {
                  final routeDetails = await _getDirections(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    position,
                  );

                  if (routeDetails != null) {
                    // Create a fake prediction for the tapped location
                    final prediction = PlacePrediction(
                      placeId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      description: 'Custom Location',
                      mainText: 'Selected Location',
                      secondaryText: 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
                      latitude: position.latitude,
                      longitude: position.longitude,
                    );

                    _handleDestinationSelected(prediction, position, routeDetails);
                  }
                } else {
                  _showSnackBar('Current location not available');
                }
              },
              child: const Text('Book Cab'),
            ),
          ],
        );
      },
    );
  }

  Future<RouteDetails?> _getDirections(LatLng origin, LatLng destination) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'key=$_apiKey&'
        'mode=driving&'
        'alternatives=false';

    try {
      print('Getting directions: $url');
      final response = await http.get(Uri.parse(url));

      print('Directions API Response Status: ${response.statusCode}');
      print('Directions API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Check if overview_polyline exists
          if (route['overview_polyline'] == null || route['overview_polyline']['points'] == null) {
            print('No polyline data found in route');
            return null;
          }

          // Decode polyline points
          final String encodedPolyline = route['overview_polyline']['points'];
          final List<LatLng> polylinePoints = _decodePolyline(encodedPolyline);

          print('Decoded ${polylinePoints.length} polyline points');

          return RouteDetails(
            distance: leg['distance']['text'] ?? 'Unknown',
            duration: leg['duration']['text'] ?? 'Unknown',
            distanceValue: leg['distance']['value'] ?? 0,
            durationValue: leg['duration']['value'] ?? 0,
            polylinePoints: polylinePoints,
            startAddress: leg['start_address'] ?? 'Unknown',
            endAddress: leg['end_address'] ?? 'Unknown',
          );
        } else {
          print('Directions API error: ${data['status']}');
          if (data['error_message'] != null) {
            print('Error message: ${data['error_message']}');
          }
          // Show more specific error messages
          String errorMsg = 'Route not found';
          if (data['status'] == 'ZERO_RESULTS') {
            errorMsg = 'No route found between these locations';
          } else if (data['status'] == 'REQUEST_DENIED') {
            errorMsg = 'API key issue or Directions API not enabled';
          } else if (data['status'] == 'OVER_QUERY_LIMIT') {
            errorMsg = 'API quota exceeded';
          }
          _showSnackBar(errorMsg);
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error response: ${response.body}');
        _showSnackBar('Network error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting directions: $e');
      _showSnackBar('Error getting directions: $e');
    }

    return null;
  }

  Future<void> _drawRouteToPosition(LatLng destination) async {
    if (_currentPosition == null) {
      _showSnackBar('Current location not available');
      return;
    }

    print('Drawing route from ${_currentPosition!.latitude},${_currentPosition!.longitude} to ${destination.latitude},${destination.longitude}');

    setState(() {
      _isLoading = true;
    });

    try {
      // Get route details from Google Directions API
      final RouteDetails? routeDetails = await _getDirections(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination,
      );

      if (routeDetails != null && routeDetails.polylinePoints.isNotEmpty) {
        setState(() {
          // Remove any existing search routes
          _polylines.removeWhere((polyline) => polyline.polylineId.value == 'search_route');

          // Add new route polyline
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('search_route'),
              points: routeDetails.polylinePoints,
              color: Colors.blue,
              width: 5,
              patterns: [],
            ),
          );
        });

        print('Route polyline added with ${routeDetails.polylinePoints.length} points');

        // Adjust camera to show the entire route
        _fitRouteInView(routeDetails.polylinePoints);

        // Show route details dialog
        _showRouteDetailsDialog(routeDetails);
      } else {
        // Fallback to straight line if directions fail
        List<LatLng> straightLinePoints = [
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          destination,
        ];

        setState(() {
          _polylines.removeWhere((polyline) => polyline.polylineId.value == 'search_route');
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('search_route'),
              points: straightLinePoints,
              color: Colors.orange,
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        });

        _showSnackBar('Showing straight line - no road route available');
      }
    } catch (e) {
      print('Error getting directions: $e');
      _showSnackBar('Error getting directions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fitRouteInView(List<LatLng> points) {
    if (points.isEmpty || _controller == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  // Enhanced polyline decoder with better error handling
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];

    if (encoded.isEmpty) {
      print('Empty polyline string');
      return polylineCoordinates;
    }

    try {
      int index = 0;
      int len = encoded.length;
      int lat = 0;
      int lng = 0;

      while (index < len) {
        int b;
        int shift = 0;
        int result = 0;
        do {
          if (index >= len) break;
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          if (index >= len) break;
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
      }

      print('Successfully decoded ${polylineCoordinates.length} points');
    } catch (e) {
      print('Error decoding polyline: $e');
    }

    return polylineCoordinates;
  }

  Widget _buildDestinationBanner() {
    if (!_showDestinationBanner || _currentRoute == null) return const SizedBox();

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedDestinationName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _dismissDestinationBanner,
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.straighten, size: 16, color: Color(0xFFF79D39)),
                        const SizedBox(width: 4),
                        Text(
                          _currentRoute!.distance,
                          style: const TextStyle(
                            color: Color(0xFFF79D39),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Color(0xFFF79D39)),
                        const SizedBox(width: 4),
                        Text(
                          _currentRoute!.duration,
                          style: const TextStyle(
                            color: Color(0xFFF79D39),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${((_currentRoute!.distanceValue / 1000) * 12).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF79D39),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Picker Field
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFFF79D39), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedDate == null ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Time Picker Field
              InkWell(
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedTime = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFF79D39), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTime == null
                              ? 'Select Time'
                              : _selectedTime!.format(context),
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedTime == null ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Passenger Count Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFFF79D39), size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _passengerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Number of Passengers',
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _bookCab,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF79D39),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_taxi, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Book Cab',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Add this widget method for cab status
  Widget _buildCabStatusBanner() {
    if (!_cabArriving) return const SizedBox();

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF79D39),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFF79D39)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF79D39),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cab Booked Successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your cab is arriving soon...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _dismissCabStatus,
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFFF79D39)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.local_taxi, color: Color(0xFFF79D39), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Driver: Manoj Kumar',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ETA: 5 min',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRouteDetailsDialog(RouteDetails routeDetails) {
    // Check if route details are valid
    if (routeDetails.duration.isEmpty || routeDetails.distance.isEmpty) {
      _showSnackBar('Route details not available');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.directions, color: Color(0xFFF79D39)),
              SizedBox(width: 8),
              Text('Route Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFF79D39), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        routeDetails.duration,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF79D39),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.straighten, color: Color(0xFFF79D39), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        routeDetails.distance,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF79D39),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('From: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4),
                  child: Text(
                    routeDetails.startAddress,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('To: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4),
                  child: Text(
                    routeDetails.endAddress,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                if (routeDetails.durationValue > 0 && routeDetails.distanceValue > 0)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.speed, size: 16, color: Colors.grey),
                            const SizedBox(height: 4),
                            Text(
                              '${(routeDetails.distanceValue / routeDetails.durationValue * 3.6).toStringAsFixed(1)} km/h',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const Text('Avg Speed', style: TextStyle(fontSize: 8, color: Colors.grey)),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.local_gas_station, size: 16, color: Colors.grey),
                            const SizedBox(height: 4),
                            Text(
                              '${(routeDetails.distanceValue / 1000 * 0.08).toStringAsFixed(1)}L',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const Text('Est. Fuel', style: TextStyle(fontSize: 8, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar('Route displayed on map');
              },
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Navigate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF79D39),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission'),
          content: const Text(
              'Location permission is required to show your current location on the map.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _drawPolyline() async {
    if (_currentPosition != null && _markers.length > 1) {
      Marker? lastMarker;
      for (Marker marker in _markers) {
        if (marker.markerId.value != 'current_location') {
          lastMarker = marker;
        }
      }

      if (lastMarker != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          // Get route details from Google Directions API
          final RouteDetails? routeDetails = await _getDirections(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            lastMarker.position,
          );

          if (routeDetails != null) {
            setState(() {
              _polylines.add(
                Polyline(
                  polylineId: PolylineId('route_${DateTime.now().millisecondsSinceEpoch}'),
                  points: routeDetails.polylinePoints,
                  color: Colors.red,
                  width: 4,
                ),
              );
            });

            // Show route details dialog
            _showRouteDetailsDialog(routeDetails);
          } else {
            // Fallback to straight line if directions fail
            List<LatLng> polylineCoordinates = [
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              lastMarker.position,
            ];

            setState(() {
              _polylines.add(
                Polyline(
                  polylineId: PolylineId('route_${DateTime.now().millisecondsSinceEpoch}'),
                  points: polylineCoordinates,
                  color: Colors.red,
                  width: 3,
                  patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                ),
              );
            });

            _showSnackBar('Straight line route drawn (no road data available)');
          }
        } catch (e) {
          print('Error drawing route: $e');
          _showSnackBar('Error drawing route');
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      _showSnackBar('Need current location and at least one marker');
    }
  }

  void _clearMap() {
    setState(() {
      _markers.clear();
      _polylines.clear();
      _showPredictions = false;
      _placePredictions.clear();
      _searchController.clear();
      _showDestinationBanner = false;
      _selectedDestination = null;
      _selectedDestinationName = '';
      _currentRoute = null;
      _cabBooked = false;
      _cabArriving = false;
    });
    _addCurrentLocationMarker();
    _showSnackBar('Map cleared');
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Add this key
       // Add this drawer
      appBar: AppBar(
        backgroundColor: Color(0xFFF79D39) ,
        title: Text('Choose Your Destination', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Google Map
          _isLoading
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading map...'),
              ],
            ),
          )
              : GoogleMap(
            initialCameraPosition: _currentPosition != null
                ? CameraPosition(
              target: LatLng(_currentPosition!.latitude,
                  _currentPosition!.longitude),
              zoom: 16,
            )
                : _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              if (_currentPosition != null) {
                _addCurrentLocationMarker();
              }
            },
            markers: _markers,
            polylines: _polylines,
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We have our own button
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            compassEnabled: true,
            trafficEnabled: false,
          ),

          // Search Bar with Autocomplete
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Search Input with Menu Button
                Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search Destination...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        // prefixIcon: IconButton(
                        //   icon: Icon(Icons.menu, color: Colors.grey[600]),
                        //   onPressed: () {
                        //     _scaffoldKey.currentState?.openDrawer();
                        //   },
                        // ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _placePredictions.clear();
                              _showPredictions = false;
                            });
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                      onChanged: (value) {
                        setState(() {}); // Trigger rebuild for clear button
                      },
                    ),
                  ),
                ),

                // Autocomplete Predictions
                if (_showPredictions && _placePredictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _placePredictions.length,
                      itemBuilder: (context, index) {
                        final prediction = _placePredictions[index];
                        return InkWell(
                          onTap: () => _selectPlace(prediction),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: index < _placePredictions.length - 1
                                  ? Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prediction.mainText,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14),
                                      ),
                                      if (prediction.secondaryText.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            prediction.secondaryText,
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Loading indicator for search
          if (_isLoading && _searchController.text.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              right: 30,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),

          // Add the destination banner
          _buildDestinationBanner(),

          // Add the cab status banner
          _buildCabStatusBanner(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "location",
            onPressed: _getCurrentLocation,
            backgroundColor: Color(0xFFF79D39),
            child: const Icon(Icons.my_location, color: Colors.white),
            tooltip: 'Get Current Location',
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: "polyline",
            onPressed: _drawPolyline,
            backgroundColor: Color(0xFFF79D39),
            child: const Icon(Icons.route, color: Colors.white),
            tooltip: 'Draw Route',
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: "clear",
            onPressed: _clearMap,
            backgroundColor: Color(0xFFF79D39),
            child: const Icon(Icons.clear, color: Colors.white),
            tooltip: 'Clear Map',
          ),
        ],
      ),
    );
  }
}

class RouteDetails {
  final String distance;
  final String duration;
  final int distanceValue; // in meters
  final int durationValue; // in seconds
  final List<LatLng> polylinePoints;
  final String startAddress;
  final String endAddress;

  RouteDetails({
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
    required this.polylinePoints,
    required this.startAddress,
    required this.endAddress,
  });
}

// Updated model class for Place Predictions using New Places API
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.latitude,
    this.longitude,
  });

  // For backwards compatibility with old API
  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ??
          json['description'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }

  // For new Places API
  factory PlacePrediction.fromNewApiJson(Map<String, dynamic> json) {
    final displayName = json['displayName']?['text'] ?? '';
    final formattedAddress = json['formattedAddress'] ?? '';
    final location = json['location'];

    return PlacePrediction(
      placeId: json['id'] ?? '',
      description: displayName.isNotEmpty ? displayName : formattedAddress,
      mainText: displayName,
      secondaryText: formattedAddress,
      latitude: location?['latitude']?.toDouble(),
      longitude: location?['longitude']?.toDouble(),
    );
  }
}
