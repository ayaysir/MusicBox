//
//  AppConfigVariables.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/10.
//

import Foundation

let PAPER_TEXTURE_LIST = [
    "Paper: Creased seamless paper texture",
    "Paper: Hand made paper with hair and fibers",
    "Paper: Handmade seamless paper texture",
    "Paper: Handmade white paper with fibers for scrapbooking",
    "Paper: Leather wallpaper",
    "Paper: Uneven white handmade paper",
    "Paper: White paper with fibers",
]

let BG_TEXTURE_LIST = [
    "Background: Melamine-wood-1",
    "Background: Melamine-wood-2",
    "Background: Melamine-wood-3",
    "Background: Melamine-wood-4",
    "Background: Melamine-wood-5",
    "Background: Melamine-wood-6",
]

struct InstrumentPatch {
    var number: Int
    var className: String
    var instName: String
}


let INST_LIST = [
    InstrumentPatch(number: 0, className: "Piano", instName: "Acoustic Grand Piano"),
    InstrumentPatch(number: 1, className: "Piano", instName: "Bright Acoustic Piano"),
    InstrumentPatch(number: 2, className: "Piano", instName: "Electric Grand Piano"),
    InstrumentPatch(number: 3, className: "Piano", instName: "Honky-tonk Piano"),
    InstrumentPatch(number: 4, className: "Piano", instName: "Rhodes Piano"),
    InstrumentPatch(number: 5, className: "Piano", instName: "Chorused Piano"),
    InstrumentPatch(number: 6, className: "Piano", instName: "Harpsichord"),
    InstrumentPatch(number: 7, className: "Piano", instName: "Clavinet"),
    InstrumentPatch(number: 8, className: "Chromatic Percussion", instName: "Celesta"),
    InstrumentPatch(number: 9, className: "Chromatic Percussion", instName: "Glockenspiel"),
    InstrumentPatch(number: 10, className: "Chromatic Percussion", instName: "Music box"),
    InstrumentPatch(number: 11, className: "Chromatic Percussion", instName: "Vibraphone"),
    InstrumentPatch(number: 12, className: "Chromatic Percussion", instName: "Marimba"),
    InstrumentPatch(number: 13, className: "Chromatic Percussion", instName: "Xylophone"),
    InstrumentPatch(number: 14, className: "Chromatic Percussion", instName: "Tubular Bells"),
    InstrumentPatch(number: 15, className: "Chromatic Percussion", instName: "Dulcimer"),
    InstrumentPatch(number: 24, className: "Guitar", instName: "Acoustic Guitar (nylon)"),
    InstrumentPatch(number: 25, className: "Guitar", instName: "Acoustic Guitar (steel)"),
    InstrumentPatch(number: 26, className: "Guitar", instName: "Electric Guitar (jazz)"),
    InstrumentPatch(number: 27, className: "Guitar", instName: "Electric Guitar (clean)"),
    InstrumentPatch(number: 28, className: "Guitar", instName: "Electric Guitar (muted)"),
    InstrumentPatch(number: 45, className: "Strings", instName: "Pizzicato Strings"),
    InstrumentPatch(number: 104, className: "Ethnic", instName: "Sitar"),
    InstrumentPatch(number: 105, className: "Ethnic", instName: "Banjo"),
    InstrumentPatch(number: 106, className: "Ethnic", instName: "Shamisen"),
    InstrumentPatch(number: 107, className: "Ethnic", instName: "Koto"),
    InstrumentPatch(number: 108, className: "Ethnic", instName: "Kalimba"),
    InstrumentPatch(number: 109, className: "Ethnic", instName: "Bagpipe"),
    InstrumentPatch(number: 110, className: "Ethnic", instName: "Fiddle"),
    InstrumentPatch(number: 111, className: "Ethnic", instName: "Shana"),
    InstrumentPatch(number: 112, className: "Percussive", instName: "Tinkle Bell"),
    InstrumentPatch(number: 113, className: "Percussive", instName: "Agogo"),
    InstrumentPatch(number: 114, className: "Percussive", instName: "Steel Drums"),
    InstrumentPatch(number: 115, className: "Percussive", instName: "Woodblock"),
    InstrumentPatch(number: 116, className: "Percussive", instName: "Taiko Drum"),
    InstrumentPatch(number: 117, className: "Percussive", instName: "Melodic Tom"),
    InstrumentPatch(number: 118, className: "Percussive", instName: "Synth Drum"),
]

