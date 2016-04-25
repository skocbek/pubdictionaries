#!/usr/bin/env ruby
require 'json'
require 'pp'

# Provide functionalities for text annotation.
# 
class TextAnnotator
  # Initialize the text annotator instance.
  #
  # * (array)  dictionaries  - The Id of dictionaries to be used for annotation.
  def initialize(dictionaries, tokens_len_min = 1, tokens_len_max = 6, threshold = 0.85, rich=false)
    @dictionaries = dictionaries
    @tokens_len_min = tokens_len_min
    @tokens_len_max = tokens_len_max
    @threshold = threshold
    @rich = rich

    @tokens_len_min ||= 1
    @tokens_len_max ||= 6
    @threshold ||= 0.85
    @rich ||= false
  end

  # Annotate an input text.
  #
  # * (string) text  - Input text.
  #
  def annotate(text)
    # tokens are produced in the order of their position
    tokens = Label.tokenize(Label.uncapitalize(text))
    span_index = {}
    (0 ... tokens.length - @tokens_len_min + 1).each do |tbegin|
      (@tokens_len_min .. @tokens_len_max).each do |tlen|
        break if tbegin + tlen > tokens.length
        break if (tokens[tbegin + tlen - 1][:position] - tokens[tbegin][:position]) > @tokens_len_max - 1

        span = text[tokens[tbegin][:start_offset]...tokens[tbegin+tlen-1][:end_offset]]

        position = {start_offset: tokens[tbegin][:start_offset], end_offset: tokens[tbegin+tlen-1][:end_offset]}

        if span_index.has_key?(span)
          span_index[span][:positions] << position
        else
          span_index[span] = {tokens: tokens[tbegin, tlen].collect{|t| t[:token]}, positions:[position]}
        end
      end
    end

    mapping = {}
    bad_key = nil
    span_index.keys.each do |span|
      unless bad_key.nil?
        next if span.start_with?(bad_key)
        bad_key = nil
      end

      r = Label.find_similar_labels(span, span_index[span][:tokens], @dictionaries, @threshold, true)

      if r[:es_results] > 0
        mapping[span] = r[:labels]
      else
        bad_key = span
      end
    end

    # To collect spans per label tag
    ltags = Hash.new([])
    mapping.each do |span, labels|
      labels.each do |label|
        ltags[label[:id]] += span_index[span][:positions].collect{|p| {span:span, position:p, label:label[:label], score:label[:score]}}
      end
    end

    # To sort the spans. unnecessary at the moment, because already sorted.
    # sort{|a, b|
    #   span_index[a][:start_offset] == span_index[b][:start_offset] ?
    #   span_index[b][:end_offset] <=> span_index[a][:end_offset] :
    #   span_index[a][:start_offset] <=> span_index[b][:start_offset]    
    # }

    # To choose the best span per label tag
    ltags.each do |label, anns|
      full_anns = anns
      best_anns = []
      full_anns.each do |ann|
        last_ann = best_anns.pop
        if last_ann.nil?
          best_anns.push(ann)
        elsif ann[:position][:start_offset] < last_ann[:position][:end_offset] #span_overlap?
          best_anns.push(ann[:score] > last_ann[:score] ? ann : last_ann) # prefer shorter span
        else
          best_anns.push(last_ann, ann)
        end
      end
      ltags[label] = best_anns
    end

    labels = mapping.values.flatten.uniq
    id_idx = labels.inject({}){|s, label| s[label[:id]] = Dictionary.get_ids(label[:id], @dictionaries); s}

    tags = Hash.new([])
    ltags.each do |label, anns|
      ids = id_idx[label]
      ids.each do |id|
        tags[id] += anns
      end
    end

    # To choose the best span per tag
    tags.each do |id, anns|
      full_anns = anns
      best_anns = []
      full_anns.each do |ann|
        last_ann = best_anns.pop
        if last_ann.nil?
          best_anns.push(ann)
        elsif ann[:position][:start_offset] < last_ann[:position][:end_offset] #span_overlap?
          best_anns.push(ann[:score] >= last_ann[:score] ? ann : last_ann) # prefer longer span
        else
          best_anns.push(last_ann, ann)
        end
      end
      tags[id] = best_anns
    end

    # tags_to_annotation
    denotations = []
    tags.each do |id, anns|
      anns.each do |ann|
        d = {span:{begin:ann[:position][:start_offset], end:ann[:position][:end_offset]}, obj:id}
        if @rich
          d[:score] = ann[:score]
          d[:label] = ann[:label]
        end
        denotations << d
      end
    end

    annotation = {
      text: text,
      denotations: denotations.uniq
    }
  end
end
