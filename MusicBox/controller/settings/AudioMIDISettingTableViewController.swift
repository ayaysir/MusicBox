//
//  AudioMIDISettingTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/11.
//

import UIKit

class AudioMIDISettingTableViewController: UITableViewController {

    @IBOutlet weak var sldDuration: UISlider!
    @IBOutlet weak var pkvInstrumentPatch: UIPickerView!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var swtPlayInSilentMode: UISwitch!
    @IBOutlet weak var sldAutosaveInterval: UISlider!
    @IBOutlet weak var lblAutosaveInterval: UILabel!
    
    
    let configStore = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pkvInstrumentPatch.delegate = self
        pkvInstrumentPatch.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // 노트 재생시간 저장값 불러오기
        var duration = configStore.integer(forKey: .cfgDurationOfNoteSound)
        if duration <= 0 {
            duration = 8
        }
        
        sldDuration.setValue(Float(duration), animated: false)
        lblDuration.text = "\(duration)"
        
        // 자동저장 간격 저장값 불러오기
        var autosaveInterval = configStore.integer(forKey: .cfgAutosaveInterval)
        if autosaveInterval <= 0 {
            autosaveInterval = 5
        }
        
        sldAutosaveInterval.setValue(Float(autosaveInterval), animated: false)
        lblAutosaveInterval.text = "\(autosaveInterval)"
        
        let patchNumber = configStore.integer(forKey: .cfgInstrumentPatch)
        let patchArrayIndex = INST_LIST.firstIndex { patch in
            return patch.number == patchNumber
        } ?? 10
        pkvInstrumentPatch.selectRow(patchArrayIndex, inComponent: 0, animated: true)
        
        let playInSilentMode = configStore.bool(forKey: .cfgPlayInSilentMode)
        swtPlayInSilentMode.isOn = playInSilentMode
        
    }
    
    @IBAction func sldActChangeDuration(_ sender: UISlider) {
        let intValue = Int(sender.value)
        sender.setValue(Float(intValue), animated: false)
        lblDuration.text = "\(intValue)"
        
        // set UserDefaults value
        configStore.set(intValue, forKey: .cfgDurationOfNoteSound)
    }
    
    @IBAction func sldActChangeAutosaveInterval(_ sender: UISlider) {
        let intValue = Int(sender.value)
        sender.setValue(Float(intValue), animated: false)
        lblAutosaveInterval.text = "\(intValue)"
        
        configStore.set(intValue, forKey: .cfgAutosaveInterval)
    }
    
    
    @IBAction func swtActChangePlayInSilentMode(_ sender: UISwitch) {
        configStore.set(sender.isOn, forKey: .cfgPlayInSilentMode)
    }
    
    
}

extension AudioMIDISettingTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        INST_LIST.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(INST_LIST[row].number): \(INST_LIST[row].instName)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        configStore.set(INST_LIST[row].number, forKey: .cfgInstrumentPatch)
    }
}
