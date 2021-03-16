//
//  ViewController.swift
//  DataCollector
//
//  Created by Ming Wang on 3/7/21.
//

// Data streams:
// Accelerometer (x,y,z,t)
// Altimeter (relative altitude, pressure)
// TODO: Add Camera
// TODO: Implement download
// * potential:
// Ambient noise - AVAudioRecorder
// Proximity sensor
// Ambient light sensor
// Gyroscope

import UIKit
import CoreMotion // accelerometer, barometer
import Charts
import AVFoundation // camera

class ViewController: UIViewController {
    // Properties
    @IBOutlet weak var startRecordButton: UIButton!
    @IBOutlet weak var stopRecordButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    
    @IBOutlet weak var accelerometerChart: LineChartView!
    @IBOutlet weak var barometerChart: LineChartView!
    @IBOutlet weak var pressureChart: LineChartView!
    @IBOutlet weak var cameraView: UIView!
    
    //Actions
    @IBAction func startRecording(_ sender: Any) {
        startDataCapture()
    }
    @IBAction func stopRecording(_ sender: Any) {
        stopDataCapture()
    }
    @IBAction func download(_ sender: Any) {
        let downloadAlert = UIAlertController(title: "Download data?", message: "This will save csv files to your phone.", preferredStyle: .alert)

        downloadAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.downloadRecordedData()
        }))
        downloadAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

        self.present(downloadAlert, animated: true)
    }
    
    let motionManager = CMMotionManager()
    let altimeter = CMAltimeter()
    
    // Data Containers
    var collectedAccelerationData: [[Double]] = []
    var collectedAltimeterData: [[Double]]  = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Initial state
        stopRecordButton.isEnabled = false
        downloadButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Setup camera

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func startDataCapture() {
        // Update button states
        startRecordButton.isEnabled = false
        stopRecordButton.isEnabled = true
        downloadButton.isEnabled = false
        
        // Reset previously recorded data if it exists
        // Clear all entries instead of reinitializing dataset?
        // Accelerometer
        accelerometerChart.data?.removeDataSetByIndex(0)
        accelerometerChart.data?.removeDataSetByIndex(1)
        accelerometerChart.data?.removeDataSetByIndex(2)
        // Barometer
        barometerChart.data?.removeDataSetByIndex(0)
        pressureChart.data?.removeDataSetByIndex(0)
        
        // Clear previously saved data
        collectedAccelerationData = []
        collectedAltimeterData = []
        
        // Set up accelerometer datasets
        let accel_x_data: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "x_accel")
        accel_x_data.drawCirclesEnabled = false
        accel_x_data.drawValuesEnabled = false
        accel_x_data.setColor(NSUIColor.blue)
        
        let accel_y_data: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "y_accel")
        accel_y_data.drawCirclesEnabled = false
        accel_y_data.drawValuesEnabled = false
        accel_y_data.setColor(NSUIColor.green)
        
        let accel_z_data: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "z_accel")
        accel_z_data.drawCirclesEnabled = false
        accel_z_data.drawValuesEnabled = false
        accel_z_data.setColor(NSUIColor.red)
        
        
        let accelData = LineChartData()
        accelData.addDataSet(accel_x_data)
        accelData.addDataSet(accel_y_data)
        accelData.addDataSet(accel_z_data)
        accelerometerChart.data = accelData
        var accelCounter = 0 // running counter of x index on line chart
        var plotCounter = 0
        let plotFrequency = 10 // plot results every nth occurrence
        
        // Set up barometer datasets
        let rel_alt_data: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "rel_alt")
        rel_alt_data.drawCirclesEnabled = false
        rel_alt_data.drawValuesEnabled = false
        rel_alt_data.setColor(NSUIColor.orange)
        
        let pressure_data: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "pressure")
        pressure_data.drawCirclesEnabled = false
        pressure_data.drawValuesEnabled = false
        pressure_data.setColor(NSUIColor.gray)
        
        let altimeterData = LineChartData()
        let pressureData = LineChartData()
        altimeterData.addDataSet(rel_alt_data)
        pressureData.addDataSet(pressure_data)
        barometerChart.data = altimeterData
        pressureChart.data = pressureData
        var altimeterCounter = 0 // running counter of x index on line chart
        
        // Check accelerometer availability
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0/60.0 // 60hz
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) {(data, error) in
                // Process x,y,z,t here
                if(data != nil){
                    if let accel = data?.acceleration, let ts = data?.timestamp {
                        plotCounter += 1
                        
                        if (plotCounter >= plotFrequency) {
                            accelCounter += 1
                            plotCounter = 0 // reset
                            
                            // Save data
                            self.collectedAccelerationData.append([accel.x, accel.y, accel.z, Double(ts)])
                            
                            // Update chart
                            self.accelerometerChart.data?.addEntry(ChartDataEntry(x: Double(accelCounter), y: accel.x), dataSetIndex: 0) // accel_x_data
                            self.accelerometerChart.data?.addEntry(ChartDataEntry(x: Double(accelCounter), y: accel.y), dataSetIndex: 1) // accel_y_data
                            self.accelerometerChart.data?.addEntry(ChartDataEntry(x: Double(accelCounter), y: accel.z), dataSetIndex: 2) // accel_z_data

                            self.accelerometerChart.notifyDataSetChanged()
                            self.accelerometerChart.updateFocusIfNeeded()
                        }
                    }
                }
            }
        } else {
            print("accelerometer not available")
        }
        
        // Check altimeter availability
        if CMAltimeter.isRelativeAltitudeAvailable() {
            // Modify update interval to match accelerometer?
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) {(data, error) in
                if (data != nil) {
                    if let alt = data?.relativeAltitude, let pressure = data?.pressure, let ts = data?.timestamp {
                        // TODO: Scale axes
                        altimeterCounter += 1
                        
                        // Save data
                        self.collectedAltimeterData.append([Double(truncating: alt), Double(truncating: pressure), ts])
                        
                        let relativeAltitude = alt.doubleValue
                        let pressure = pressure.doubleValue
                        // print("relative altitude: \(relativeAltitude)  pressure: \(pressure)")
                        // Typical pressure: 101
                        // Relative altitude: fluctuates, below 1
                        self.barometerChart.data?.addEntry(ChartDataEntry(x: Double(altimeterCounter), y: relativeAltitude), dataSetIndex: 0) // rel_alt_data
                        self.pressureChart.data?.addEntry(ChartDataEntry(x: Double(altimeterCounter), y: pressure), dataSetIndex: 0) // pressure_data

                        self.barometerChart.notifyDataSetChanged()
                        self.barometerChart.updateFocusIfNeeded()
                        self.pressureChart.notifyDataSetChanged()
                        self.pressureChart.updateFocusIfNeeded()
                    }
                }
            }
        } else {
            print("altimeter not available")
        }
    }
    
    func stopDataCapture() {
        startRecordButton.isEnabled = true
        stopRecordButton.isEnabled = false
        downloadButton.isEnabled = true
        
        // Stop measurements
        motionManager.stopAccelerometerUpdates()
        altimeter.stopRelativeAltitudeUpdates()
    }
    
    func downloadRecordedData() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let accelUrl = documentsPath.appendingPathComponent("acceleration.csv")
            let altimeterUrl = documentsPath.appendingPathComponent("altimeter.csv")
            
            // Accelerometer
            var accelCSVText = "x,y,z,t\n"
            for pt in collectedAccelerationData {
                let newline = "\(pt[0]),\(pt[1]),\(pt[2]),\(pt[3])\n"
                accelCSVText.append(newline)
            }
            
            // Altimeter
            var altiCSVText = "relative_altitude,pressure,t\n"
            for pt in collectedAltimeterData {
                let newline = "\(pt[0]),\(pt[1]),\(pt[2])\n"
                altiCSVText.append(newline)
            }
            
            // Download Accelerometer values
            do {
                try accelCSVText.write(to: accelUrl, atomically: true, encoding: String.Encoding.utf8)
                try altiCSVText.write(to: altimeterUrl, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Failed to create file: \(error)")
            }
        }
    }
}

