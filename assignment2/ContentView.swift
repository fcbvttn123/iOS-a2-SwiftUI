import SwiftUI
import MapKit

struct AnnotationData : Identifiable {
    let id = UUID()
    let name : String
    let coordinate : CLLocationCoordinate2D
}

struct RouteSteps : Identifiable {
    let id = UUID()
    let step : String
}

struct ContentView: View {
    // State Variables
    @State var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.60775375366211, longitude: -79.66155242919922),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State var annotationArray = [
        AnnotationData(
            name: "Tran's House",
            coordinate: CLLocationCoordinate2D(latitude: 43.60775375366211, longitude: -79.66155242919922)
        )
    ]
    @State var firstStop : String = ""
    @State var secondStop : String = ""
    @State var finalDestination : String = ""
    @State var startToStop1ToStop2ToDestination : [RouteSteps] = []
    @State var startToStop1 : [RouteSteps] = []
    @State var stop1ToStop2 : [RouteSteps] = []
    @State var instructionButtonText: String = "Please fill out the form above"
    @State var isLocationValid = false
    // Screen
    var body: some View {
        NavigationView {
            ZStack {
                Image("images")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    VStack(spacing: 15) {
                        TextField("First Stop", text: $firstStop)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .foregroundColor(.black)

                        TextField("Second Stop", text: $secondStop)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .foregroundColor(.black)

                        TextField("Final Destination", text: $finalDestination)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .foregroundColor(.black)

                        Button(action: {
                            handleTextBoxClick()
                        }) {
                            Text("Submit")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(15)
                    Map(coordinateRegion: $region, annotationItems: annotationArray) { item in
                        MapPin(coordinate: item.coordinate)
                    }
                    .frame(height: 300)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    NavigationLink(
                        destination: InstructionView(
                            startToStop1ToStop2ToDestination: startToStop1ToStop2ToDestination,
                            startToStop1: startToStop1,
                            stop1ToStop2: stop1ToStop2,
                            stop1Text: firstStop,
                            stop2Text: secondStop,
                            destinationText: finalDestination
                        )
                    ) {
                        Text(instructionButtonText)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(!isLocationValid)
                }
                .padding(.top, 50)
            }
        }
    }
    // Functions
    func handleTextBoxClick() {
        let firstStopText = firstStop
        let secondStoptext = secondStop
        let finalDestinationtext = finalDestination
        let clGeocoderObj = CLGeocoder()
        // --------Home to First Stop: Start--------
        clGeocoderObj.geocodeAddressString(
            firstStopText,
            completionHandler: {(possiblePlaces, error) in
                if(error != nil) {
                    print("Error finding the location 1")
                    instructionButtonText = "\(firstStopText) is not found"
                    isLocationValid = false
                    return
                }
                if let firstPlace = possiblePlaces?.first {
                    var coordinates : CLLocationCoordinate2D = firstPlace.location!.coordinate
                    region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
                    annotationArray.append(AnnotationData(name: firstPlace.name!, coordinate: coordinates))
                    let directionRequest = createDirectionRequest(
                        startCoordinates: CLLocationCoordinate2D(latitude: 43.60775375366211, longitude: -79.66155242919922),
                        destinationCoordinates: coordinates
                    )
                    calculateDirection(request: directionRequest) { steps in
                        startToStop1ToStop2ToDestination = steps.map { $0 }
                    }
                    // --------First Stop to Second Stop: Start--------
                    clGeocoderObj.geocodeAddressString(
                        secondStoptext,
                        completionHandler: {(possiblePlaces, error) in
                            if(error != nil) {
                                print("Error finding the location 2")
                                instructionButtonText = "\(secondStoptext) is not found"
                                isLocationValid = false
                                return
                            }
                            if let firstPlace = possiblePlaces?.first {
                                var coordinates2 : CLLocationCoordinate2D = firstPlace.location!.coordinate
                                region = MKCoordinateRegion(center: coordinates2, latitudinalMeters: 1000, longitudinalMeters: 1000)
                                annotationArray.append(AnnotationData(name: firstPlace.name!, coordinate: coordinates2))
                                let directionRequest = createDirectionRequest(
                                    startCoordinates: coordinates,
                                    destinationCoordinates: coordinates2
                                )
                                calculateDirection(request: directionRequest) { steps in
                                    startToStop1 = steps.map { $0 }
                                }
                                // --------Second Stop to Final Destination: Start--------
                                clGeocoderObj.geocodeAddressString(
                                    finalDestinationtext,
                                    completionHandler: {(possiblePlaces, error) in
                                        if(error != nil) {
                                            print("Error finding the destination")
                                            instructionButtonText = "\(finalDestinationtext) is not found"
                                            isLocationValid = false
                                            return
                                        }
                                        if let firstPlace = possiblePlaces?.first {
                                            var coordinates3 : CLLocationCoordinate2D = firstPlace.location!.coordinate
                                            region = MKCoordinateRegion(center: coordinates3, latitudinalMeters: 1000, longitudinalMeters: 1000)
                                            annotationArray.append(AnnotationData(name: firstPlace.name!, coordinate: coordinates3))
                                            let directionRequest = createDirectionRequest(
                                                startCoordinates: coordinates2,
                                                destinationCoordinates: coordinates3
                                            )
                                            calculateDirection(request: directionRequest) { steps in
                                                stop1ToStop2 = steps.map { $0 }
                                            }
                                            isLocationValid = true
                                            instructionButtonText = "Instructions"
                                        }
                                    }
                                )
                                // --------Second Stop to Final Destination: End--------
                            }
                        }
                    )
                    // --------First Stop to Second Stop: End--------
                }
            }
        )
        // --------Home to First Stop: End--------
    }
    func createDirectionRequest(startCoordinates : CLLocationCoordinate2D, destinationCoordinates : CLLocationCoordinate2D)
    -> MKDirections.Request {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinates))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinates))
        request.requestsAlternateRoutes = false
        request.transportType = .automobile
        return request
    }
    func calculateDirection(request: MKDirections.Request, completion: @escaping ([RouteSteps]) -> Void) {
        var instructionArray: [RouteSteps] = []
        let direction = MKDirections(request: request)
        direction.calculate { response, error in
            guard let routes = response?.routes else {
                completion([])
                return
            }
            for route in routes {
                for step in route.steps {
                    instructionArray.append(RouteSteps(step: step.instructions))
                }
            }
            completion(instructionArray)
        }
    }
}

#Preview {
    ContentView()
}
