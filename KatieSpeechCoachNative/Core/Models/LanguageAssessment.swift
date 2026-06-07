import Foundation

/// KAT-206: Language-transfer coaching snapshots, extracted from AppViewModel.
///
/// Maps a learner's `firstLanguage` + `otherLanguages` strings to a
/// `LanguageAssessmentSnapshot` that names the most likely transfer pattern,
/// the sound focus, and a prosody focus for a hypothetical first rep.
///
/// The matcher is heuristic and best-effort — Katie uses it as a starting
/// hypothesis and only confirms by listening to the user's own recordings.
/// All branches return the same shape so the UI can render them uniformly.
enum LanguageAssessment {
    /// Build a snapshot from the learner's language fields.
    static func snapshot(firstLanguage: String, otherLanguages: String) -> LanguageAssessmentSnapshot {
        let languageText = [firstLanguage, otherLanguages]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
            .lowercased()

        if languageText.contains("spanish") {
            return LanguageAssessmentSnapshot(
                title: "Spanish-English listening plan",
                transferPattern: "Watch for final consonants and linked-word pacing to blur when the sentence speeds up.",
                soundFocus: "Keep clear consonant endings on /t/, /d/, /s/, and /z/ before the next word takes over.",
                prosodyFocus: "Use a small pause before the main stress so the sentence does not run too evenly.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie checks your own recordings, not a language stereotype."
            )
        }

        if languageText.contains("mandarin") || languageText.contains("cantonese") {
            return LanguageAssessmentSnapshot(
                title: "Tone-language listening plan",
                transferPattern: "Watch for vowel length and word stress to matter more than they do in a tone language.",
                soundFocus: "Separate nearby consonants cleanly, especially contrasts like /l/ and /r/ or voiced and voiceless stops.",
                prosodyFocus: "Give the stressed word a little more lift and a clear pitch change on the key phrase.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie checks your own recordings, not a language stereotype."
            )
        }

        if languageText.contains("arabic") {
            return LanguageAssessmentSnapshot(
                title: "Arabic-English listening plan",
                transferPattern: "Watch for short function words to blur when English rhythm speeds up.",
                soundFocus: "Check mid-vowel clarity and consonant clusters, especially at the start or end of words.",
                prosodyFocus: "Let the sentence fall at the end so the listener hears the completion clearly.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie checks your own recordings, not a language stereotype."
            )
        }

        if languageText.contains("japanese") {
            return LanguageAssessmentSnapshot(
                title: "Japanese-English listening plan",
                transferPattern: "Watch for English stress timing and consonant contrasts to flatten when the sentence speeds up.",
                soundFocus: "Protect listener-critical contrasts like /l/ vs /r/, word-final consonants, and short function words that can disappear under pressure.",
                prosodyFocus: "Use one clearer stress peak and a more definite sentence landing before adding broader melody work.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie starts with language-transfer possibilities, then checks your own recordings for what actually repeats."
            )
        }

        if languageText.contains("korean") {
            return LanguageAssessmentSnapshot(
                title: "Korean-English listening plan",
                transferPattern: "Watch for tense/lax consonant contrasts and reduced function words to blur when English rhythm gets compressed.",
                soundFocus: "Protect word-final consonants, cluster clarity, and the exact consonant contrast that changes the listener’s meaning load.",
                prosodyFocus: "Add one cleaner stress target and sentence ending before trying to widen pitch movement across the whole line.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie uses language background as a starting guess, then checks your own speech for repeated listener friction."
            )
        }

        if languageText.contains("hindi") || languageText.contains("urdu") || languageText.contains("hinglish") {
            return LanguageAssessmentSnapshot(
                title: "South Asian English listening plan",
                transferPattern: "Watch for dental/alveolar contrasts and unstressed function words to blur when the sentence speeds up.",
                soundFocus: "Keep listener-critical endings and contrasts like /w/ vs /v/ or /t/ vs /th/ distinct only where they change meaning for the listener.",
                prosodyFocus: "Protect one clear stress peak and a cleaner sentence landing before adding extra melody work.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie starts from your language background, then checks what your own recordings actually repeat."
            )
        }

        if languageText.contains("portuguese") {
            return LanguageAssessmentSnapshot(
                title: "Portuguese-English listening plan",
                transferPattern: "Watch for vowel reduction and word-final consonants to soften when English gets faster.",
                soundFocus: "Keep the key content word crisp, especially the ending consonant and the vowel contrast that carries the meaning.",
                prosodyFocus: "Use one deliberate pause before the main point so the sentence does not feel equally stressed all the way through.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie checks repeated patterns in your own speech instead of making a broad accent claim."
            )
        }

        if languageText.contains("french") {
            return LanguageAssessmentSnapshot(
                title: "French-English listening plan",
                transferPattern: "Watch for nasal vowels and syllable timing to carry over into English rhythm.",
                soundFocus: "Keep the English vowel contrast a little wider so key words do not collapse together.",
                prosodyFocus: "Add a clearer stress peak on the listener-critical word, not every word equally.",
                caveat: "This is a coaching hypothesis, not a diagnosis. Katie checks your own recordings, not a language stereotype."
            )
        }

        // Default fallback when no language is selected or it's an unsupported one.
        return LanguageAssessmentSnapshot(
            title: "General listening plan",
            transferPattern: "Katie will listen for the patterns your own recordings repeat, instead of assuming a one-size-fits-all accent issue.",
            soundFocus: "Look for the sounds that most often blur, drop, or change when you are under pressure.",
            prosodyFocus: "Notice where a pause, stress, or sentence ending would make the listener work less.",
            caveat: "This is a coaching hypothesis, not a diagnosis. Katie uses your profile as a starting point, then listens to your own speech."
        )
    }
}
