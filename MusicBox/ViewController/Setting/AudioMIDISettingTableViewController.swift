//
//  AudioMIDISettingTableViewController.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/11.
//

import UIKit
import GoogleMobileAds

class AudioMIDISettingTableViewController: UITableViewController {
  
  private var bannerView: BannerView!
  
  @IBOutlet weak var sldDuration: UISlider!
  @IBOutlet weak var pkvInstrumentPatch: UIPickerView!
  @IBOutlet weak var lblDuration: UILabel!
  @IBOutlet weak var swtPlayInSilentMode: UISwitch!
  @IBOutlet weak var swtPlayPitchWhenInputNotes: UISwitch!
  @IBOutlet weak var sldAutosaveInterval: UISlider!
  @IBOutlet weak var lblAutosaveInterval: UILabel!
  @IBOutlet weak var collectionViewChangeAppIcon: UICollectionView!
  
  let configStore = UserDefaults.standard
  
  // indexPath
  private let durationEachNote_IxP = IndexPath(row: 0, section: 0)
  private let midiPatch_IxP = IndexPath(row: 0, section: 1)
  private let playSoundInilentMode_IxP = IndexPath(row: 0, section: 2)
  private let playPitchWhenInput_IxP = IndexPath(row: 1, section: 2)
  private let autosaveInterval_IxP = IndexPath(row: 0, section: 3)
  private let appIconChange_IxP = IndexPath(row: 0, section: 4)
  private let bannerAdArea_IxP = IndexPath(row: 0, section: 5)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    pkvInstrumentPatch.delegate = self
    pkvInstrumentPatch.dataSource = self
    
    // == 앱 아이콘 변경 == //
    collectionViewChangeAppIcon.delegate = self
    collectionViewChangeAppIcon.dataSource = self
    
    // ====== 광고 ====== //
    TrackingTransparencyPermissionRequest()
    if AdManager.isReallyShowAd {
      bannerView = setupBannerAds(self, adUnitID: AdInfo.shared.setting)
    }
    
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
    
    swtPlayPitchWhenInputNotes.isOn = configStore.bool(forKey: .cfgPlayPitchWhenInputNotes)
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    
    // 현재 선택된 아이콘 이름 불러오기
    if let currentIconName = UIApplication.shared.alternateIconName {
      let rowIndex = APP_ICON_LIST.firstIndex(of: currentIconName) ?? 0
      collectionViewChangeAppIcon.selectItem(at: IndexPath(row: rowIndex, section: 0), animated: false, scrollPosition: .left)
    } else {
      collectionViewChangeAppIcon.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .left)
    }
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    bannerView?.fitInView(self)
  }
  
  override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    switch indexPath {
    case durationEachNote_IxP:
      simpleAlert(self, message: "Sets the duration of the note in seconds. The longer, the more natural playback will be. Some instruments may not work properly. The default is 8".localized, title: "Duration of Each Note during Playback".localized, handler: nil)
    case midiPatch_IxP:
      simpleAlert(self, message: "You can set the playback instrument. The default instrument is “10: Music Box”.".localized, title: "MIDI Instrument Patch".localized, handler: nil)
    case autosaveInterval_IxP:
      simpleAlert(self, message: "This app supports autosave. You can set the autosave interval in seconds. Smaller values can slow execution. The default is 10.".localized, title: "Autosave Interval".localized, handler: nil)
    case playSoundInilentMode_IxP:
      simpleAlert(self, message: "Turning this switch on will play sound even in silent mode. You may need to restart the app.".localized, title: "Play Sound in Silent Mode".localized, handler: nil)
    case playPitchWhenInput_IxP:
      simpleAlert(self, message: "When this switch is turned on, a pitch sound (musical tone) is played whenever a note is entered on the paper.".localized, title: "Play Pitch Sound".localized, handler: nil)
    default:
      break
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    let originalHeight = super.tableView(tableView, heightForHeaderInSection: section)
    
    switch section {
    case playSoundInilentMode_IxP.section:
      return originalHeight * 0.5
    default:
      break
    }
    
    return originalHeight
  }
  
  override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    let originalHeight = super.tableView(tableView, heightForHeaderInSection: section)
    
    switch section {
    case playSoundInilentMode_IxP.section:
      return originalHeight * 0.5
    case bannerAdArea_IxP.section:
      return !AdManager.isReallyShowAd ? 0.1 : originalHeight
    default:
      break
    }
    
    return originalHeight
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == bannerAdArea_IxP.section {
      return 0
    }
    
    return super.tableView(tableView, numberOfRowsInSection: section)
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
  
  @IBAction func swtActPlayPitchWhenInputNotes(_ sender: UISwitch) {
    configStore.set(sender.isOn, forKey: .cfgPlayPitchWhenInputNotes)
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

extension AudioMIDISettingTableViewController: UICollectionViewDataSource, UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    APP_ICON_LIST.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AppIconCell", for: indexPath) as? AppIconCell else {
      return UICollectionViewCell()
    }
    cell.update(imageName: APP_ICON_LIST[indexPath.row])
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) else {
      return
    }
    
    cell.isSelected = true
    
    if UIApplication.shared.supportsAlternateIcons {
      if indexPath.row == 0 {
        UIApplication.shared.setAlternateIconName(nil, completionHandler: nil)
      } else {
        UIApplication.shared.setAlternateIconName(APP_ICON_LIST[indexPath.row], completionHandler: nil)
      }
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) else {
      return
    }
    
    cell.isSelected = false
  }
}

extension AudioMIDISettingTableViewController:  UICollectionViewDelegateFlowLayout  {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: 60, height: 60)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    // 셀 간 간격
    return 5
  }
}

class AppIconCell: UICollectionViewCell {
  
  override var isSelected: Bool {
    didSet {
      if isSelected {
        setBorder(borderWidth: 5, borderColor: UIColor.red)
      } else {
        setBorder(borderWidth: 5, borderColor: UIColor.clear)
      }
    }
  }
  
  func update(imageName: String) {
    let iconImage = UIImage(named: imageName)
    self.backgroundView = UIImageView(image: iconImage)
    self.layer.cornerRadius = 10
    self.layer.masksToBounds = true
    setBorder(borderWidth: 5, borderColor: UIColor.clear)
  }
  
  private func setBorder(borderWidth: CGFloat, borderColor: UIColor) {
    self.layer.borderWidth = borderWidth
    self.layer.borderColor = borderColor.cgColor
  }
}

