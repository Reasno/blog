---
title: "Kubernetes on Premise: Top 5 Fallacies (Part One)"
date: 2019-07-29T13:08:10+08:00
draft: false
toc: true
tags:
- Kubernetes
---

As the saying goes, Kubernetes is gradually eating the world of software. In the last year, we have switched our on premise infrastructure from Docker Swarm to Kubernetes. Adopting Kubernetes on the cloud is one thing; adopting it on premise and making it production ready is quite another. Many lessons have been learned along our journey. For those who have played with Kubernetes in the vacuum, there are probably some hidden deadly trap yet to be revealed. Hopefully this article can share some light on things you do not want to miss before running you production work load on Kubernetes.

## 1 Running Kubernetes is easy.

Well, running your work load in Kubernetes is relatively easy. Running Kubernetes itself is much challenging. As a result, Kubernetes is much more lovely and smooth on cloud platforms. Leveraging the cloud would definitely give you a head start in Kubernetes adoption, though engineer everything by yourself (your team) would give you deeper understanding.

When  I span up a new cluster locally for the first time I used kubeadm. After it was up, I realized I forgot to add a command-line argument to kubeadm init so I painfully tore it down and started over again. Should I have a thorough knowledge I would know I could simply edit manifests in /etc/kubernetes to achieve the same effect. 

Keeping up the cluster is no easier. The containerized environment brings a bunch of new concepts on top of the classic distributed system puzzles. Overlay network, certificate-(re)signing, CI/CD, DNS, routing, scaling, and many other aspects could go wrong. Often proficiency in both traditional linux world and containerized cloud native world are required to debug a platform failure. 

Kubernetes the hard way is a fine guide to unfold the internals of Kubernetes. To successfully maintain a production ready cluster on premise, the hard way might be the only way.

## 2 YAML keeps resources organized.

We all appreciate the declarative nature of Kubernetes resources. So much so that we extend it describe many application level objects, creating little CRDs everywhere. Those YAML files looks like a perfect tool to organize your cluster, until they inevitably  pile up.

Keep them in the source control is a must. Even then you probably need to categorize them into different repo based on your need. Some form of templating system is desired in order to reuse common component. Helm is the most popular choice. Writing your own helm chart is sadly quite verbose. I create helm chart only if I need to use the chart for more than one release, i.e. staging and production.

Tools are still evolving.