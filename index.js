'use strict';

import React from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  Image,
  ScrollView,
  TextInput
} from 'react-native';
import HelloWorld from './HelloWorldNativeModule';
import Layout from "./Layout";

class RNHighScores extends React.Component {

  render() {
    return (
      <ScrollView style={styles.container}>
        <View style={styles.realTimeView}>
        <View style={styles.iconContainer}>
        <Image
          style={{ width: 25, height: 23, resizeMode: 'contain', marginRight: 4 }}
          source={require('./assets/Shape.png')}
        /><Text>{this.props.details.hrate}</Text>
        </View>
        <View style={styles.iconContainer}>
        <Image
          style={{ width: 25, height: 23, resizeMode: 'contain', marginRight: 4 }}
          source={require('./assets/Temp.png')}
        /><Text>{this.props.details.temperature}</Text>
        </View>
        <View style={styles.iconContainer}>
        <Image
          style={{ width: 25, height: 23, resizeMode: 'contain', marginRight: 4 }}
          source={require('./assets/Sensor.png')}
        /><Text>On</Text>
        </View>
        </View>
        <Image
          source={require("./assets/bench-press.gif")}
          style={styles.exerciseImage}
        />
        <Text style={styles.exerciseName}>Bench Press</Text>

        <View style={{flexDirection: 'row', justifyContent: 'space-between', marginHorizontal: 16}}>
        <View style={{ flexDirection: "row" }}>
          <TextInput style={[styles.h2, styles.textInputs]} placeholder="60" />
          <Text style={styles.h2}>kg</Text>
        </View>
        <View style={{ flexDirection: "row" }}>
          <TextInput style={[styles.h2, styles.textInputs]} placeholder="10" />
          <Text style={styles.h2}>reps</Text>
        </View>
        </View>


        <View style={styles.instructionsContainer}>
          <Text style={styles.h1}>Instructions</Text>
          <Text style={styles.paragraph}>
            Lay down on the bench. Then, using your thighs to help raise the
            dumbbells up.
          </Text>
          <Text style={styles.h1}>Caution</Text>
          <Text style={styles.paragraph}>
            When you are done, do not drop the dumbbells next to you as this is
            dangerous to your rotator cuff in your shoulders and others working
            out around you.
          </Text>
          <Text style={styles.h1}>Variations</Text>
          <Text style={styles.paragraph}>
            Another variation of this exercise is to perform it with the palms
            of the hands facing each other.
          </Text>
          <View style={{flexDirection: 'row', justifyContent: 'space-between'}}>
          <Text style={styles.h1}>X: {this.props.details.axisX} </Text>
          <Text style={styles.h1}>Y: {this.props.details.axisY} </Text>
          <Text style={styles.h1}>Z: {this.props.details.axisZ} </Text>
          </View>
        </View>
      </ScrollView>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  exerciseImage: {
    width: Layout.window.width * 0.95,
    height: 200,
    marginBottom: 16,
    marginLeft: -24,
    alignSelf: 'flex-start'
  },
  exerciseName: {
    color: "#212121",
    marginBottom: 16,
    fontSize: 24,
    marginLeft: 16,
    lineHeight: 30,
    fontWeight: "bold",
    backgroundColor: "transparent"
  },
  realTimeView: {
    position: 'absolute',
    top: 100,
    right: 16,
    zIndex: 100,
  },
  iconContainer: {
    flexDirection: 'row', 
    alignItems: 'center', 
    marginBottom: 4
  },
  instructionsContainer: {
    flex: 1,
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: "transparent",
    borderBottomWidth: 0.5,
    borderBottomColor: "#CDCDCD"
  },
  h1: {
    color: "#212121",
    marginBottom: 8,
    fontSize: 16,
    lineHeight: 21,
    fontWeight: "bold",
    backgroundColor: "transparent"
  },
  h2: {
    color: "#212121",
    fontSize: 30,
    fontWeight: "bold",
    backgroundColor: "transparent"
  },
  textInputs: {
    marginRight: 8, 
    borderBottomColor: '#000', 
    borderBottomWidth: 2
  },
  paragraph: {
    color: "rgba(0,0,0,0.8)",
    marginVertical: 8,
    fontSize: 16,
    lineHeight: 22,
    backgroundColor: "transparent"
  }
});

// Module name
AppRegistry.registerComponent('RNHighScores', () => RNHighScores);