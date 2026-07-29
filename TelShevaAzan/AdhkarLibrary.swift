import Foundation

enum AdhkarCategory: String, CaseIterable, Identifiable {
    case morning
    case evening
    case afterPrayer
    case sleep
    case waking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning:
            return "الصباح"
        case .evening:
            return "المساء"
        case .afterPrayer:
            return "بعد الصلاة"
        case .sleep:
            return "النوم"
        case .waking:
            return "الاستيقاظ"
        }
    }

    var subtitle: String {
        switch self {
        case .morning:
            return "ابدأ يومك بذكر الله"
        case .evening:
            return "اختم يومك بالطمأنينة"
        case .afterPrayer:
            return "أذكار ما بعد الفريضة"
        case .sleep:
            return "أذكار قبل النوم"
        case .waking:
            return "ما يقال عند الاستيقاظ"
        }
    }

    var symbol: String {
        switch self {
        case .morning:
            return "sunrise.fill"
        case .evening:
            return "sunset.fill"
        case .afterPrayer:
            return "person.fill"
        case .sleep:
            return "moon.stars.fill"
        case .waking:
            return "sun.max.fill"
        }
    }

    static var suggestedNow: AdhkarCategory {
        let hour = PrayerEngine.calendar.component(.hour, from: Date())
        switch hour {
        case 4..<12:
            return .morning
        case 16..<24:
            return .evening
        case 0..<4:
            return .sleep
        default:
            return .afterPrayer
        }
    }
}

struct AdhkarItem: Identifiable, Hashable {
    let id: String
    let title: String
    let text: String
    let target: Int
    let source: String
    var note: String? = nil
}

enum AdhkarLibrary {
    static func items(for category: AdhkarCategory) -> [AdhkarItem] {
        switch category {
        case .morning:
            return morning
        case .evening:
            return evening
        case .afterPrayer:
            return afterPrayer
        case .sleep:
            return sleep
        case .waking:
            return waking
        }
    }

    private static let ayatAlKursi = """
    اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ، لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ، لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ، مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ، يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ، وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ، وَلَا يَئُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ.
    """

    private static let alIkhlas = """
    قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ.
    """

    private static let alFalaq = """
    قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ، مِنْ شَرِّ مَا خَلَقَ، وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ، وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ، وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ.
    """

    private static let alNas = """
    قُلْ أَعُوذُ بِرَبِّ النَّاسِ، مَلِكِ النَّاسِ، إِلَٰهِ النَّاسِ، مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ، الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ، مِنَ الْجِنَّةِ وَالنَّاسِ.
    """

    private static let sayyidAlIstighfar = """
    اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي؛ فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.
    """

    private static let sharedMorningEvening: [AdhkarItem] = [
        AdhkarItem(
            id: "ayat-kursi",
            title: "آية الكرسي",
            text: ayatAlKursi,
            target: 1,
            source: "سورة البقرة · الآية 255"
        ),
        AdhkarItem(
            id: "ikhlas",
            title: "سورة الإخلاص",
            text: alIkhlas,
            target: 3,
            source: "سورة الإخلاص · أبو داود والترمذي"
        ),
        AdhkarItem(
            id: "falaq",
            title: "سورة الفلق",
            text: alFalaq,
            target: 3,
            source: "سورة الفلق · أبو داود والترمذي"
        ),
        AdhkarItem(
            id: "nas",
            title: "سورة الناس",
            text: alNas,
            target: 3,
            source: "سورة الناس · أبو داود والترمذي"
        ),
        AdhkarItem(
            id: "sayyid-istighfar",
            title: "سيد الاستغفار",
            text: sayyidAlIstighfar,
            target: 1,
            source: "رواه البخاري"
        ),
        AdhkarItem(
            id: "bismillah-protection",
            title: "حفظ من الضرر",
            text: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ.",
            target: 3,
            source: "رواه أبو داود والترمذي"
        ),
        AdhkarItem(
            id: "raditu",
            title: "رضيت بالله ربًا",
            text: "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا.",
            target: 3,
            source: "رواه أحمد وأبو داود والترمذي"
        ),
        AdhkarItem(
            id: "subhanallah-100",
            title: "تسبيح اليوم",
            text: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.",
            target: 100,
            source: "رواه مسلم"
        )
    ]

    static let morning: [AdhkarItem] = [
        AdhkarItem(
            id: "morning-opening",
            title: "أصبحنا والملك لله",
            text: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ. رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.",
            target: 1,
            source: "رواه مسلم"
        )
    ] + sharedMorningEvening

    static let evening: [AdhkarItem] = [
        AdhkarItem(
            id: "evening-opening",
            title: "أمسينا والملك لله",
            text: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا. رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.",
            target: 1,
            source: "رواه مسلم"
        )
    ] + sharedMorningEvening.map { item in
        AdhkarItem(
            id: "evening-\(item.id)",
            title: item.title,
            text: item.text,
            target: item.target,
            source: item.source,
            note: item.note
        )
    }

    static let afterPrayer: [AdhkarItem] = [
        AdhkarItem(
            id: "prayer-istighfar",
            title: "الاستغفار",
            text: "أَسْتَغْفِرُ اللَّهَ.",
            target: 3,
            source: "رواه مسلم"
        ),
        AdhkarItem(
            id: "prayer-salam",
            title: "اللهم أنت السلام",
            text: "اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.",
            target: 1,
            source: "رواه مسلم"
        ),
        AdhkarItem(
            id: "prayer-ayat-kursi",
            title: "آية الكرسي",
            text: ayatAlKursi,
            target: 1,
            source: "سورة البقرة · الآية 255"
        ),
        AdhkarItem(
            id: "prayer-tahlil",
            title: "التهليل",
            text: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ.",
            target: 1,
            source: "متفق عليه"
        ),
        AdhkarItem(
            id: "prayer-subhanallah",
            title: "التسبيح",
            text: "سُبْحَانَ اللَّهِ.",
            target: 33,
            source: "رواه مسلم"
        ),
        AdhkarItem(
            id: "prayer-alhamdulillah",
            title: "التحميد",
            text: "الْحَمْدُ لِلَّهِ.",
            target: 33,
            source: "رواه مسلم"
        ),
        AdhkarItem(
            id: "prayer-allahu-akbar",
            title: "التكبير",
            text: "اللَّهُ أَكْبَرُ.",
            target: 33,
            source: "رواه مسلم",
            note: "ثم تمام المئة: لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير."
        )
    ]

    static let sleep: [AdhkarItem] = [
        AdhkarItem(
            id: "sleep-name",
            title: "باسمك أموت وأحيا",
            text: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.",
            target: 1,
            source: "رواه البخاري"
        ),
        AdhkarItem(
            id: "sleep-ayat-kursi",
            title: "آية الكرسي",
            text: ayatAlKursi,
            target: 1,
            source: "سورة البقرة · الآية 255 · رواه البخاري"
        ),
        AdhkarItem(
            id: "sleep-muawwidhat",
            title: "المعوذات",
            text: "\(alIkhlas)\n\n\(alFalaq)\n\n\(alNas)",
            target: 3,
            source: "رواه البخاري",
            note: "اجمع كفيك، وانفث فيهما، واقرأ السور ثم امسح ما استطعت من جسدك."
        ),
        AdhkarItem(
            id: "sleep-surrender",
            title: "دعاء النوم",
            text: "اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ.",
            target: 1,
            source: "متفق عليه"
        ),
        AdhkarItem(
            id: "sleep-tasbih",
            title: "تسبيح فاطمة",
            text: "سُبْحَانَ اللَّهِ 33، وَالْحَمْدُ لِلَّهِ 33، وَاللَّهُ أَكْبَرُ 34.",
            target: 1,
            source: "متفق عليه"
        )
    ]

    static let waking: [AdhkarItem] = [
        AdhkarItem(
            id: "waking-praise",
            title: "الحمد لله الذي أحيانا",
            text: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ.",
            target: 1,
            source: "متفق عليه"
        ),
        AdhkarItem(
            id: "waking-body",
            title: "الحمد لله الذي عافاني",
            text: "الْحَمْدُ لِلَّهِ الَّذِي عَافَانِي فِي جَسَدِي، وَرَدَّ عَلَيَّ رُوحِي، وَأَذِنَ لِي بِذِكْرِهِ.",
            target: 1,
            source: "رواه الترمذي"
        ),
        AdhkarItem(
            id: "waking-tawhid",
            title: "ذكر الاستيقاظ ليلًا",
            text: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. الْحَمْدُ لِلَّهِ، وَسُبْحَانَ اللَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ. اللَّهُمَّ اغْفِرْ لِي.",
            target: 1,
            source: "رواه البخاري"
        )
    ]
}

