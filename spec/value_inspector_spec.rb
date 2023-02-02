# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/appmap/value_inspector"

describe AppMap::ValueInspector do
  let(:parent_id) { nil }
  let(:exception) { nil }
  let(:max_depth) { nil }
  let(:max_array_elements) { nil }
  let(:schema) {
    options = {}
    options[:max_depth] = max_depth if max_depth
    options[:max_array_elements] = max_array_elements if max_array_elements
    AppMap::ValueInspector.detect_schema value, **options
  }

  describe "Hash value" do
    let(:value) { { id: 1, contents: "some text" } }
    it "is a one level schema" do
      expect(schema).to eq(
        class: "Hash",
        properties: [
          { name: :id, class: "Integer" },
          { name: :contents, class: "String" },
        ],
      )
    end
  end

  describe "nested Hash value" do
    let(:value) { { page: { page_number: 1, page_size: 20, total: 2383 } } }
    it "is a two level schema" do
      expect(schema).to eq(
        class: "Hash",
        properties: [
          {
            name: :page,
            class: "Hash",
            properties: [
              { name: :page_number, class: "Integer" },
              { name: :page_size, class: "Integer" },
              { name: :total, class: "Integer" },
            ],
          },
        ],
      )
    end
    describe "max depth" do
      let(:max_depth) { 1 }
      it "respects max depth" do
        expect(schema).to eq(
          class: "Hash",
          properties: [
            {
              name: :page,
              class: "Hash",
            },
          ],
        )
      end
    end
  end

  describe "Array of Hashes" do
    let(:value) { [{ id: 1, contents: "some text" }, { id: 2 }] }
    it "is an array containing the schema" do
      expect(schema).to eq(
        class: "Array",
        items: [
          {
            class: "Hash",
            properties: [
              { name: :id, class: "Integer" },
              { name: :contents, class: "String" },
            ],
          },
          {
            class: "Hash",
            properties: [ { name: :id, class: "Integer" } ]
          }
        ],
      )
    end

    describe "max depth" do
      let(:max_depth) { 0 }
      it "exceeds max_depth to describe element types when inspecting arrays" do
        expect(schema).to eq(
          class: "Array",
          items: [ { class: "Hash" } ]
        )
      end
    end
  end

  describe "Nested arrays" do
    let(:value) { [ [[[1]], [[2]]], [[[3]], [[4]]] ] }
    let(:max_depth) { 1 }
    it "exceeds max depth to get type information" do
      expect(schema).to eq(
        class: "Array",
        items: [
          {
            class: "Array",
            items: [
              class: "Array",
              items: [
                {
                  class: "Array",
                  items: [
                    { class: "Integer" }
                  ]
                }
              ]
            ]
          }
        ]
      )
    end

    describe "with Hashes" do
      let(:max_depth) { 2 }
      let(:value) do
        [
          {
            id: 0,
            children: [
              { id: 1, children: [ { id: 2 } ] },
              { id: 3, children: [ { id: 4 } ] }
            ]
          }
        ]
      end

      it "won't exceed max_depth when inspecting a Hash" do
        expect(schema).to eq(
          class: "Array",
          items: [
            {
              class: "Hash",
              properties: [
                { name: :id, class: "Integer" },
                { name: :children, class: "Array", items: [ { class: "Hash" } ] }
              ]
            }
          ]
        )
      end
    end
  end

  describe "Array of Strings" do
    let(:value) { %w[one two three] }
    it "is an array containing the schema" do
      expect(schema).to eq(
        class: "Array",
        items: [
          { class: "String" },
        ],
      )
    end
  end

  describe "Mixed array" do
    let(:value) { [ 1, "two", { key: "three" } ] }
    it "correctly describes the schema" do
      expect(schema).to eq(
        class: "Array",
        items: [
          { class: "Integer" },
          { class: "String" },
          { class: "Hash", properties: [ { name: :key, class: "String" } ] },
        ],
      )
    end
  end

  describe "Max array elements" do
    let(:value) { [ 1, 'two', { id: 3 }, [ 'four' ] ] }
    let(:max_array_elements) { 3 }

    it "only describes the first N elements" do
      expect(schema).to eq(
        class: "Array",
        items: [
          { class: "Integer" },
          { class: "String" },
          { class: "Hash", properties: [ { name: :id, class: "Integer" } ] },
        ],
      )
    end
  end

  describe "String" do
    let(:value) { "hello world" }
    it "correctly describes the schema" do
      expect(schema).to eq(
        class: "String",
      )
    end
  end

  describe "Hash with Array of Strings" do
    let(:value) { { items: %w[one two three] } }
    it "results in a two level schema" do
      expect(schema).to eq(
        class: "Hash",
        properties: [
          {
            name: :items,
            class: "Array",
            items: [
              { class: "String" },
            ],
          },
        ],
      )
    end
  end

  describe "mixed content of nested objects and arrays" do
    let(:value) do
      { "items" => [{ "id" => 1,
                     "category" => "abc",
                     "chargebee_plan_id" => "abc",
                     "country" => "vn",
                     "created_at" => "2022-11-23T06:03:09.399Z",
                     "is_current" => true,
                     "is_insurance" => false,
                     "is_public" => true,
                     "offering_key" => "abc",
                     "plan_type" => nil,
                     "price" => 1,
                     "stripe_plan_id" => nil,
                     "stripe_price_id" => nil,
                     "updated_at" => "2022-11-23T06:03:09.399Z" }],
       "default_plan_id" => 1,
       "page" => { "page_index" => 1,
                   "page_size" => 20,
                   "page_offset" => 1,
                   "page_prev_offset" => 1 } }
    end

    it "detects all elements" do
      expect(schema).to eq(
        class: "Hash",
        properties: [
          {
            :class => "Array",
            :name => "items",
            :items => [
              {
                :class => "Hash",
                :properties => [
                  { :class => "Integer", :name => "id" },
                  { :class => "String", :name => "category" },
                  { :class => "String", :name => "chargebee_plan_id" },
                  { :class => "String", :name => "country" },
                  { :class => "String", :name => "created_at" },
                  { :class => "TrueClass", :name => "is_current" },
                  { :class => "FalseClass", :name => "is_insurance" },
                  { :class => "TrueClass", :name => "is_public" },
                  { :class => "String", :name => "offering_key" },
                  { :class => "NilClass", :name => "plan_type" },
                  { :class => "Integer", :name => "price" },
                  { :class => "NilClass", :name => "stripe_plan_id" },
                  { :class => "NilClass", :name => "stripe_price_id" },
                  { :class => "String", :name => "updated_at" }
                ]
              },
            ],
          },
          {
            :class => "Integer",
            :name => "default_plan_id",
          },
          {
            :class => "Hash",
            :name => "page",
            :properties => [
              { :class => "Integer", :name => "page_index" },
              { :class => "Integer", :name => "page_size" },
              { :class => "Integer", :name => "page_offset" },
              { :class => "Integer", :name => "page_prev_offset" },
            ],
          },
        ],
      )
    end
  end
end
