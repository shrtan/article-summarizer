from gnews import GNews
from newspaper import Article
from newspaper import Config
google_news = GNews()
google_news.language = 'english'
google_news.max_results = 30
import openai
from fastapi import FastAPI


#summarizer = pipeline("summarization", model="facebook/bart-large-cnn")

openai.api_key = "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"

user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'
config = Config()
config.browser_user_agent = user_agent
# sent_detector = nltk.data.load('tokenizers/punkt/english.pickle')

# def paragraphs(sentences_list):
#     paragraph = []
#     sentence_len = 0
#     for i in range(len(sentences_list)):
#         print(sentences_list[i])
#         sen_len = 0
#         sen_len = len(sentences_list[i].split()) + sentence_len
#         if sen_len < 60:
#             sent += sentences_list[i]
#             sentence_len = sen_len
#             del sentences_list[i]
#         else:
#             #print(sent + "-------------------------\n")
#             paragraph.append(sent)
#             print(paragraph)
#             sentence_len = 0
#             sent = ""
#     paragraph.append(sent)
#     return paragraph
app = FastAPI()
        
def summarize(article_text):
    response = openai.Completion.create(
    model="text-davinci-002",
    prompt="Write a summary for the news article with a brief explanation for all the main points:\n" + article_text,
    temperature=0.5,
    max_tokens=450,
    top_p=1,
    frequency_penalty=0,
    presence_penalty=0
)
    return response["choices"][0]["text"]

@app.get("/")
def read_root():
    return {"Hello": "World"}

@app.get("/keyword_search")
def keyword_news(keyword):
    news = google_news.get_news(keyword)
    f = open("C:/Users/Shreya/Documents/Internship/News_summary/summaries/" + keyword+ "_summary.txt", 'w')
    for i in range(5):
        try:
            print(news[i]['url'])
            article = Article(news[i]['url'])
            article.download()
            article.parse()
            article.nlp()
            summary = summarize(article.text)
            f.write(article.title + "\n")
            f.write(article.url + "\n")
            f.write(summary + "\n\n")
        except:
            continue
    f.close()



