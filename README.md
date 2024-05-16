# simple_picker_widget

**This is a fork of [jorgesanure-pub-dep](https://gitlab.com/jorgesanure-pub-dep)'s. [Original Package](https://gitlab.com/jorgesanure-pub-dep/show-custom-time-picker/) is no longer maintained. Kudos To Him 👍**

It is a custom showTimePicker to allow you set a selectableTimePredicate like you do in showDatePicker.

<img src="https://github.com/shamrat1/simple_time_picker/assets/demo.gif" height='300px'>

```dart
showCustomTimePicker(
    context: context,
    // It is a must if you provide selectableTimePredicate
    onFailValidation: (context) => print('Unavailable selection'),
    initialTime: TimeOfDay(hour: 2, minute: 0),
    selectableTimePredicate: (time) =>
        time.hour > 1 &&
        time.hour < 14 &&
        time.minute % 10 == 0).then((time) =>
    setState(() => selectedTime = time?.format(context)))
```

[DEMO](https://dartpad.dartlang.org/5c32e473c8c1c9687966453d0dcf42de?)

You can see a complete sample in `example/example.dart` file
