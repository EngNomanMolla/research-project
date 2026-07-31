import 'package:flutter/material.dart';

enum UrgencyLevel { low, medium, high, emergency }

class TriageResult {
  final String careLevelEn;
  final String careLevelBn;
  final UrgencyLevel urgency;
  final Color color;
  final String descriptionBn;
  final String adviceBn;
  final String firstAidBn;
  final String audioScriptBn;

  TriageResult({
    required this.careLevelEn,
    required this.careLevelBn,
    required this.urgency,
    required this.color,
    required this.descriptionBn,
    required this.adviceBn,
    required this.firstAidBn,
    required this.audioScriptBn,
  });
}

class TriageService {
  static TriageResult analyzeSymptoms(String symptomText, {
    required int age,
    required String gender,
    required bool isSmoker,
    required double? weight,
    required bool hasDiabetes,
    required bool hasHighBP,
  }) {
    final text = symptomText.toLowerCase();

    // Risk factors warning messages
    String riskSuffixBn = '';
    String riskAudioBn = '';
    
    if (hasDiabetes && hasHighBP) {
      riskSuffixBn = ' (আপনার ডায়াবেটিস ও উচ্চ রক্তচাপ দুই-ই রয়েছে, তাই ঝুঁকি আরও বেশি)';
      riskAudioBn = ' আপনার ডায়াবেটিস এবং উচ্চ রক্তচাপ রয়েছে, যা ঝুঁকি বাড়ায়।';
    } else if (hasDiabetes) {
      riskSuffixBn = ' (আপনার ডায়াবেটিস রয়েছে, তাই ক্ষত বা ইনফেকশনের ঝুঁকি বেশি)';
      riskAudioBn = ' আপনার ডায়াবেটিস থাকার কারণে অতিরিক্ত সতর্কতা প্রয়োজন।';
    } else if (hasHighBP) {
      riskSuffixBn = ' (আপনার উচ্চ রক্তচাপ বা হাই প্রেসার রয়েছে, যা জটিলতার ঝুঁকি বাড়ায়)';
      riskAudioBn = ' আপনার উচ্চ রক্তচাপ থাকার কারণে স্ট্রোক বা হার্ট অ্যাটাকের ঝুঁকি বেশি।';
    }

    // Rule 1: Diabetes & Wounds/Cuts -> High Risk (District Hospital)
    if (hasDiabetes && (text.contains('কাটা') || text.contains('ক্ষত') || text.contains('ঘা') || text.contains('wound') || text.contains('cut') || text.contains('injury') || text.contains('ফোড়া') || text.contains('phora'))) {
      return TriageResult(
        careLevelEn: 'District Sadar Hospital',
        careLevelBn: 'জেলা সদর হাসপাতাল',
        urgency: UrgencyLevel.high,
        color: const Color(0xFFE29578), // Orange
        descriptionBn: 'জেলা সদর হাসপাতাল। আপনার ডায়াবেটিস থাকায় ক্ষত বা ঘা দ্রুত ইনফেকশনে রূপ নিতে পারে, যা পচনের সৃষ্টি করে। তাই বিশেষজ্ঞ সার্জন বা মেডিসিন ডাক্তার দেখানো জরুরি।',
        adviceBn: 'ডায়াবেটিস রোগীর পায়ে বা শরীরে যেকোনো ক্ষতে কবিরাজি কাদা, চুন বা ভেষজ পাতা লাগাবেন না। এতে দ্রুত গ্যাংগ্রিন (পচন) ধরতে পারে এবং পা কেটে ফেলার প্রয়োজন হতে পারে।',
        firstAidBn: 'ক্ষত স্থানটি পরিষ্কার স্যাভলন পানি বা নরমাল স্যালাইন দিয়ে ধুয়ে জীবাণুমুক্ত গজ কাপড় দিয়ে ঢেকে রাখুন। কোনো ভেষজ মলম লাগাবেন না।',
        audioScriptBn: 'সতর্কতা! আপনার ডায়াবেটিস থাকার কারণে অতিরিক্ত সতর্কতা প্রয়োজন। ক্ষত বা ঘা দ্রুত ইনফেকশনে রূপ নিতে পারে, তাই জেলা সদর হাসপাতালে বিশেষজ্ঞ ডাক্তার দেখান। কবিরাজি কাদা বা চুন লাগাবেন না।$riskAudioBn',
      );
    }

    // Rule 3: Emergency Level - RED (Specialized Hospital / Medical College)
    if (text.contains('বুকে ব্যথা') || 
        text.contains('buk betha') || 
        text.contains('chest pain') ||
        text.contains('বুক ধড়ফড়') || 
        text.contains('heart') ||
        text.contains('stroke') ||
        text.contains('অবশ') ||
        text.contains('paralysis') ||
        text.contains('প্যারালাইসিস') ||
        text.contains('অজ্ঞান') || 
        text.contains('ogyan') || 
        text.contains('unconscious') ||
        text.contains('তীব্র শ্বাসকষ্ট') || 
        text.contains('shash kosto') ||
        text.contains('গলায় আটকে') ||
        text.contains('choking') ||
        text.contains('পুড়ে যাওয়া') ||
        text.contains('পুড়ে') ||
        text.contains('আগুনে') ||
        text.contains('burn') ||
        text.contains('দুর্ঘটনা') ||
        text.contains('accident') ||
        text.contains('রক্তক্ষরণ') ||
        text.contains('হাঁপানি') ||
        text.contains('asthma') ||
        (text.contains('গর্ভবতী') && text.contains('রক্ত')) ||
        (text.contains('pregnancy') && text.contains('bleed'))) {
      
      return TriageResult(
        careLevelEn: 'Medical College & Specialized Hospital',
        careLevelBn: 'মেডিকেল কলেজ ও বিশেষায়িত হাসপাতাল',
        urgency: UrgencyLevel.emergency,
        color: const Color(0xFFE63946), // Red
        descriptionBn: 'এটি একটি জরুরি অবস্থা। জেলা বা জাতীয় পর্যায়ের বড় সরকারি মেডিকেল কলেজ হাসপাতাল যেখানে হৃদরোগ, ব্রেন স্ট্রোক, গুরুতর অগ্নিকাণ্ডে পোড়া ক্ষত, দম বন্ধ হওয়া বা জটিল অস্ত্রোপচারের বিশেষ ব্যবস্থা রয়েছে।$riskSuffixBn',
        adviceBn: 'কোনো কবিরাজ বা ভুয়া ডাক্তারের কাছে গিয়ে সময় নষ্ট করবেন না। বুকে ব্যথা, শরীরের একপাশ অবশ হওয়া বা মারাত্মক পুড়ে যাওয়ার মতো সমস্যা অবহেলা করলে রোগীর অঙ্গহানি বা প্রাণহানি হতে পারে।',
        firstAidBn: 'দম বন্ধ হলে পিঠে চাপড় দিন বা সিপিআর এর ব্যবস্থা করুন। আগুনে পুড়লে প্রচুর ঠান্ডা পানি ক্ষতস্থানে ঢালুন (মিনিট ২০ ধরে)। তাৎক্ষণিকভাবে অ্যাম্বুলেন্স ডাকুন বা ১৬২৬৩ নম্বরে কল করুন।',
        audioScriptBn: 'জরুরি সতর্কতা! রোগীকে অবিলম্বে মেডিকেল কলেজ বা বড় বিশেষায়িত হাসপাতালে নিয়ে যান। কবিরাজ বা হাতুড়ে ডাক্তারের ওঝাগিরি বা পানি পড়া দিয়ে মূল্যবান সময় নষ্ট করবেন না। রোগীকে দ্রুত হাসপাতালে নেওয়া জীবন বাঁচাতে পারে।$riskAudioBn',
      );
    }

    // Rule 4: High Level - ORANGE (District Hospital)
    if (text.contains('ভাঙ্গা') || 
        text.contains('bhanga') || 
        text.contains('fracture') ||
        text.contains('মচকে') ||
        text.contains('sprain') ||
        text.contains('রক্তবমি') || 
        text.contains('blood vomit') ||
        text.contains('চোখের সমস্যা') || 
        text.contains('চোখ লাল') ||
        text.contains('চোখ') ||
        text.contains('ঝাপসা') ||
        text.contains('eye') ||
        text.contains('কোমর ব্যথা') ||
        text.contains('কুকুর') ||
        text.contains('বিড়াল') ||
        text.contains('কামড়') ||
        text.contains('bite') ||
        text.contains('আঘাত') ||
        text.contains('injury') ||
        text.contains('মাথা') ||
        text.contains('কীটনাশক') ||
        text.contains('বিষ') ||
        text.contains('poison') ||
        text.contains('pregnancy') || 
        text.contains('প্রেগন্যান্ট') || 
        text.contains('গর্ভবতী') ||
        (isSmoker && text.contains('কাশি')) ||
        text.contains('সাপ') || 
        text.contains('snake')) {
      
      return TriageResult(
        careLevelEn: 'District Sadar Hospital',
        careLevelBn: 'জেলা সদর হাসপাতাল',
        urgency: UrgencyLevel.high,
        color: const Color(0xFFE29578), // Orange/Amber
        descriptionBn: 'জেলা সদর হাসপাতাল, যেখানে বিশেষজ্ঞ চিকিৎসক (যেমন- গাইনি, চক্ষু, অর্থোপেডিক্স), এক্স-রে এবং জলাতঙ্কের ভ্যাকসিন বা বিষের প্রতিষেধক (এন্টি-ভেনম) এর সুব্যবস্থা রয়েছে।$riskSuffixBn',
        adviceBn: 'হাড় ভাঙা বা সাপে ও কুকুরে কামড়ানোর ঘটনায় কবিরাজের ঝাঁড়ফুঁক, শিকড়-বাকড় বা বিষ নামানোর ওঝার কাছে যাবেন না। বিষাক্ত বিষ শরীরে ছড়িয়ে পড়তে পারে।',
        firstAidBn: 'কুকুরে কামড়ালে ক্ষারযুক্ত সাবান ও প্রচুর রানিং ওয়াটার দিয়ে ক্ষতস্থান ১৫ মিনিট ধুয়ে নিন। সাপে কামড়ালে আক্রান্ত অঙ্গ স্থির রাখুন। বিষ পান করলে রোগীকে জোর করে বমি করাবেন না, সরাসরি হাসপাতালে নিয়ে যান।',
        audioScriptBn: 'আপনার লক্ষণ অনুযায়ী জেলা সদর হাসপাতালে গিয়ে বিশেষজ্ঞ ডাক্তার দেখানো উচিত। হাড় ভাঙা, কুকুরের কামড়, বিষ খাওয়া বা চোখের গুরুতর সমস্যায় ওঝা বা কবিরাজের ভুল চিকিৎসা নেবেন না। সরাসরি হাসপাতালে যান।$riskAudioBn',
      );
    }

    // Rule 5: Medium Level - YELLOW (Upazila Health Complex)
    if (text.contains('জ্বর') || 
        text.contains('jwor') || 
        text.contains('fever') ||
        text.contains('ডেঙ্গু') ||
        text.contains('dengue') ||
        text.contains('জন্ডিস') ||
        text.contains('jaundice') ||
        text.contains('হলুদ') ||
        text.contains('দাঁত') ||
        text.contains('tooth') ||
        text.contains('প্রস্রাব') ||
        text.contains('urine') ||
        text.contains('জ্বালা') ||
        text.contains('জ্বালাপোড়া') ||
        text.contains('কান') ||
        text.contains('ear') ||
        text.contains('অনিদ্রা') ||
        text.contains('sleep') ||
        text.contains('বমি') || 
        text.contains('bomi') || 
        text.contains('vomit') ||
        text.contains('পেট ব্যথা') || 
        text.contains('pet betha') || 
        text.contains('stomach pain') ||
        text.contains('ডায়রিয়া') || 
        text.contains('diarrhea') || 
        text.contains('পাতলা পায়খানা') ||
        text.contains('কাশি') || 
        text.contains('kashi') || 
        text.contains('cough')) {
      
      return TriageResult(
        careLevelEn: 'Upazila Health Complex',
        careLevelBn: 'উপজেলা স্বাস্থ্য কমপ্লেক্স',
        urgency: UrgencyLevel.medium,
        color: const Color(0xFFF4A261), // Warm Yellow
        descriptionBn: 'উপজেলা স্বাস্থ্য কমপ্লেক্স (থানা হাসপাতাল)। এখানে জেনারেল ডাক্তার বসেন এবং রক্ত পরীক্ষা, ডেন্টাল ইউনিট ও ডেঙ্গু পরীক্ষার সুবিধা আছে।$riskSuffixBn',
        adviceBn: 'জ্বর, ডেঙ্গু বা জন্ডিস হলে কবিরাজের ভেষজ রস বা গাছের পাতার রস সেবন করবেন না, এতে লিভার ড্যামেজ হতে পারে। ডাক্তারের পরামর্শ ব্যতীত কোনো ওষুধ খাবেন না।',
        firstAidBn: 'ডেঙ্গু ও জ্বরের জন্য মাথায় জলপট্টি দিন এবং প্রচুর তরল খাবার (স্যুপ, ডাবের পানি) খাওয়ান। দাঁত ব্যথার জন্য হালকা গরম লবণ পানি দিয়ে কুলি করুন। প্রস্রাবে সমস্যা হলে প্রচুর পানি পান করুন।',
        audioScriptBn: 'আপনার উপসর্গের জন্য উপজেলা স্বাস্থ্য কমপ্লেক্সে গিয়ে একজন এমবিবিএস ডাক্তার দেখান। জন্ডিস বা ডেঙ্গুর মতো রোগের ক্ষেত্রে কবিরাজের শিকড় খাওয়া বা গাছগাছড়ার ভেষজ রস খাওয়া থেকে সম্পূর্ণ বিরত থাকুন।$riskAudioBn',
      );
    }

    // Rule 6: Low Level - GREEN (Community Clinic)
    return TriageResult(
      careLevelEn: 'Community Clinic',
      careLevelBn: 'কমিউনিটি ক্লিনিক',
      urgency: UrgencyLevel.low,
      color: const Color(0xFF2A9D8F), // Teal Green
      descriptionBn: 'কমিউনিটি ক্লিনিক (ওয়ার্ড পর্যায়ে)। এটি সম্পূর্ণ ফ্রি সরকারি সেবা কেন্দ্র, যেখানে সর্দি, কাশি, সাধারণ চুলকানি বা গর্ভবতী মহিলাদের প্রাথমিক পরামর্শ এবং প্রায় ৩০ ধরনের সাধারণ ওষুধ ফ্রিতে দেওয়া হয়।$riskSuffixBn',
      adviceBn: 'ছোটখাটো ঠান্ডা, সর্দি বা চুলকানির জন্য শহরের বড় হাসপাতালে গিয়ে ভিড় করার প্রয়োজন নেই। ঘরের কাছে কমিউনিটি ক্লিনিক থেকেই ফ্রি চিকিৎসা ও ওষুধ পেতে পারেন।',
      firstAidBn: 'কুসুম গরম পানি দিয়ে গোসল করুন। সর্দির জন্য আদা-চা বা মধু খেতে পারেন। শরীর পরিষ্কার পরিচ্ছন্ন রাখুন। পেটে গ্যাসের সমস্যা হলে ওরস্যালাইন বা ডাবের পানি পান করতে পারেন।',
      audioScriptBn: 'আপনার সমস্যাটি সাধারণ। আপনি আপনার বাড়ির কাছের কমিউনিটি ক্লিনিকে গেলেই ফ্রিতে ডাক্তার দেখাতে পারবেন এবং সরকারি ওষুধ পাবেন। বড় হাসপাতালে গিয়ে সময় ও টাকা নষ্ট করার প্রয়োজন নেই।$riskAudioBn',
    );
  }
}
