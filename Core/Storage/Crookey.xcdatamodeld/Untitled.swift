//
//  Untitled.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" lastSavedToolsVersion="21754">
    <entity name="SavedRecipe" representedClassName="SavedRecipe" syncable="YES" codeGenerationType="class">
        <attribute name="dateAdded" optional="YES" attributeType="Date"/>
        <attribute name="id" attributeType="Integer 64" defaultValueString="0"/>
        <attribute name="image" optional="YES" attributeType="String"/>
        <attribute name="instructions" optional="YES" attributeType="String"/>
        <attribute name="readyInMinutes" attributeType="Integer 16" defaultValueString="0"/>
        <attribute name="servings" attributeType="Integer 16" defaultValueString="0"/>
        <attribute name="summary" optional="YES" attributeType="String"/>
        <attribute name="title" attributeType="String"/>
        <relationship name="ingredients" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="SavedIngredient" inverseName="recipe" inverseEntity="SavedIngredient"/>
    </entity>
    <entity name="SavedIngredient" representedClassName="SavedIngredient" syncable="YES" codeGenerationType="class">
        <attribute name="amount" attributeType="Double" defaultValueString="0.0"/>
        <attribute name="id" attributeType="Integer 64" defaultValueString="0"/>
        <attribute name="image" optional="YES" attributeType="String"/>
        <attribute name="name" attributeType="String"/>
        <attribute name="unit" attributeType="String"/>
        <relationship name="recipe" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="SavedRecipe" inverseName="ingredients" inverseEntity="SavedRecipe"/>
    </entity>
    <entity name="ShoppingListItem" representedClassName="ShoppingListItem" syncable="YES" codeGenerationType="class">
        <attribute name="amount" attributeType="Double" defaultValueString="0.0"/>
        <attribute name="dateAdded" attributeType="Date"/>
        <attribute name="id" attributeType="Integer 64" defaultValueString="0"/>
        <attribute name="isChecked" attributeType="Boolean" defaultValueString="NO"/>
        <attribute name="name" attributeType="String"/>
        <attribute name="unit" attributeType="String"/>
    </entity>
</model>
