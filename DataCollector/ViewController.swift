//
//  ViewController.swift
//  DataCollector
//
//  Created by Ming Wang on 3/7/21.
//

// Data streams:
// Accelerometer
// Altimeter
// * potential:
// Ambient noise
// Proximity sensor
// Ambient light sensor
// Gyroscope

import UIKit
import CoreMotion
import Charts

class ViewController: UIViewController {
    // Properties
    @IBOutlet weak var accelerometerChart: LineChartView!
    @IBOutlet weak var barometerChart: LineChartView!
    
    let motionManager = CMMotionManager()
    let altimeter = CMAltimeter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
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
        altimeterData.addDataSet(rel_alt_data)
        altimeterData.addDataSet(pressure_data)
        barometerChart.data = altimeterData
        var altimeterCounter = 0 // running counter of x index on line chart
        
        
        
        // Check accelerometer availability
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) {(data, error) in
                // Process x,y,z, t here
                if(data != nil){
                    if let accel = data?.acceleration {
                        accelCounter += 1

                        self.accelerometerChart.data?.addEntry(ChartDataEntry(x: Double(accelCounter), y: accel.x), dataSetIndex: 0) // accel_x_data
                        self.accelerometerChart.data?.addEntry(ChartDataEntry(x: Double(accelCounter), y: accel.y), dataSetIndex: 1) // accel_y_data
                        self.accelerometerChart.data?.addEntry(ChartDataEntry(x: Double(accelCounter), y: accel.z), dataSetIndex: 2) // accel_z_data
                        
                        self.accelerometerChart.notifyDataSetChanged()
                        self.accelerometerChart.updateFocusIfNeeded()
                        
                    }
                }
            }
        } else {
            print("accelerometer not available")
        }
        
        // Check altimeter availability
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) {(data, error) in
                if (data != nil) {
                    if let alt = data?.relativeAltitude, let pressure = data?.pressure {
                        
                        altimeterCounter += 1
                        let relativeAltitude = alt.doubleValue
                        let pressure = pressure.doubleValue
                        print("relative altitude: \(relativeAltitude)  pressure: \(pressure)")
                        // Typical pressure: 101
                        // Relative altitude: fluctuates, below 1
                        self.barometerChart.data?.addEntry(ChartDataEntry(x: Double(altimeterCounter), y: relativeAltitude), dataSetIndex: 0) // rel_alt_data
                        self.barometerChart.data?.addEntry(ChartDataEntry(x: Double(altimeterCounter), y: pressure), dataSetIndex: 1) // pressure_data
                        
                        self.barometerChart.notifyDataSetChanged()
                        self.barometerChart.updateFocusIfNeeded()
                    }
                }
            }
            
        }
    }
    

}

